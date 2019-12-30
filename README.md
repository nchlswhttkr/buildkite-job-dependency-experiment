# buildkite-job-dependency-experiment

https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment

Just trying out some newer features in Buildkite, with [step dependencies](https://buildkite.com/changelog/84-introducing-pipeline-step-dependencies) and [input steps](https://buildkite.com/docs/pipelines/input-step) (which seem to be partially released and documented).

This is mostly a log of me observing and debugging a series of builds, and me trying to dissect some of the behaviour I encountered.

---

### Steps with a missing dependency

In the case of the first run, the `answer` I assumed the the key used for each field would be accessible as a step dependency. This isn't true, and it isn't possible to submit a single field without filling out all fields. You can however place a `key` field on the input block itself, and depend on this.

[One line from the docs](https://buildkite.com/docs/pipelines/dependencies#order-of-operations) seems a bit confusing, and it could probably do with some clarification.

> If the step you're dependent on doesn't exist, the build will fail without running the step that is waiting for the dependency.

From what I could gauge from the [build itself](https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/2), this build should have failed because the `answer` step depended on a step key that didn't exist. There was a field with the key in the input step, but it seems step keys and field keys are not different. The command itself for the `answer` step had a typo in it, but that doesn't matter because the job was not scheduled and run.

My guess would be that the build was stuck waiting for a step with the desired key to be created, so it could run that and then run the `answer` step. The build stayed "running" (do builds eventually time out if its left with no jobs scheduled or running?). The documentations imply to me that the build would immediately fail with some kind of "no step with key `<key>` was found for step `answer`, and the build failed" error message.

Perhaps the lack of immediate failure is intentional, to wait for a job to be created?

### All steps can have a key

The current docs show the `key` field as only being available for command steps, but all steps can have a `depends_on` field. The `key` field for `fields` on an input/block step are for meta-data keys, not step keys.

We can show that all fields support a key attribute with a [build with a set of command steps](https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/15) that each depends on a different step type.

In this case, each respective command step ran after the step it depended on passed, so they can have keys.

---

### First run

Commit `e00b067f` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/2

I provisioned one agent for this, and it seemed to run linearly.

Yep, inputs do not block `three` and `four` from running! All fields need to filled out though, you cannot submit just one.

At the moment you can't tell whether `three` would have run without the first waiter unblocking. I'll need more agents so that jobs can run concurrently to investigate.

After I unblocked the continue, the later jobs (`answer` and `five`) did not start immediately running.

After 10 minutes I cancelled the build. The seemingly blocked job (key `answer`) had not started.

So in this case the input step did not block the succeeding command steps `three` and `four`, but did block the `answer` job because it had a `depends_on` for one of the inputs. In the end, once the input was given the job did not become unblocked and resume.

For the next run I'm going to remove the `depends_on` from `answer`, but still try to print the value from the meta-data store (~with a default value provided in case~ *). I'm going to try and wait for this `answer` job to run before filling in the input.

I'll leave the concurrent agent changes investigation stuff for another run.

\* I forgot the default value, see notes from the second run.

### Second run

Commit `02488e2b` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/3

So I forgot the set the default value and the `answer` job failed. It did run without waiting for the input step though.

### Third run

Commit `d5d66a79` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/4

I made a typo and forgot to include the actual subcommand. Should have been `buildkite-agent meta-data get first-field --default "NOT SET"`

### Fourth run

Commit `869c1c80` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/5

So `answer` ran without waiting for input (rightly so), and the remaining waiter and job went after it.

The build then went into blocked mode, waiting for me to fill out the input. When I filled out the input, the build remained blocked (as of about 3-4 minutes later).

I'm going to up the agents now to see if that allows job `three` to run before the first waiter.

I'm gonna record the results and wrap up for tonight with this next run. Will probably pick up again tomorrow morning.

### Fifth run

Commit `824c4698` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/6

So I mucked up when running the extra agents, because I just ran them from terminal sessions. This caused problems at runtime and the jobs got stuck waiting for user input.

Looking at the timelines, job `three` did start before job `one` had finished (before the first waiter unblocked) though.

Once `one` finished, `four` and `five` started as well, since the first waiter only depended on `one` and not on `two`.

I think I'll just [follow the tutorial](https://buildkite.com/docs/tutorials/parallel-builds#running-multiple-agents) to set up multiple agents properly though...

### Sixth run

Commit `824c4698` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/7

A permissions error prevented the build agent from starting its job. This was due to the previous step's mistake which messed up the build environment. The build directories for some agents were owned by root instead of buildkite-agent. In hindsight I really should have done it this way...

### Seventh run

Commit `824c4698` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/8

Much like the fifth run, jobs `one`, `two` and `three` were all scheduled immediately, without `three` depending on the waiter. After that the second set of jobs ran, and later the final job (`five`).

Seems to be running as expected. I'm going to update the comments in the YAML file to identify when they run. You can check this against the timeline of each step within Buildkite.

The most noticable error was saying that the input step would depend on the waiter, which isn't true because inputs don't "create any dependencies to the steps before and after it" [[1]](https://buildkite.com/docs/pipelines/input-step).
