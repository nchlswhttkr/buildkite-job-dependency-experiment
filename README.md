# test

https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment

### First run

Commit `e00b067f` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/2

I provisioned one agent for this, and it seemed to run linearly.

Yep, inputs do not block `three` and `four` from running! All fields need to filled out though, you cannot submit just one.

At the moment you can't tell whether `three` would have run without the first waiter unblocking. I'll need more agents so that jobs can run concurrently to investigate.

After I unblocked the continue, the later jobs (`answer` and `five`) did not start immediately running.

After 10 minutes I cancelled the build. The seemingly blocked job (key `answer`) had not started.

So in this case the input job did not block the succeeding command steps `three` and `four`, but did block the `answer` job because it had a `depends_on` for one of the inputs. In the end, once the input was given the job did not become unblocked and resume.

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

The job then went into blocked mode, waiting for me to fill out the input. When I filled out the input, the build remained blocked (as of about 3-4 minutes later).

I'm going to up the agents now to see if that allows job `three` to run before the first waiter.

I'm gonna record the results and wrap up for tonight with this next run. Will probably pick up again tomorrow morning.