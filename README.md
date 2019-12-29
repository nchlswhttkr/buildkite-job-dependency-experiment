# test

https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment

### First run

Commit `e00b067f2e0bfea8d39a7176c0280a73647712de` // Build https://buildkite.com/nchlswhttkr/dependencies-and-input-experiment/builds/2

I provisioned one agent for this, and it seemed to run linearly.

Yep, inputs do not block `three` and `four` from running! All fields need to filled out though, you cannot submit just one.

At the moment you can't tell whether `three` would have run without the first waiter unblocking. I'll need more agents so that jobs can run concurrently to investigate.

After I unblocked the continue, the later jobs (`answer` and `five`) did not start immediately running.

After 10 minutes I cancelled the build. The seemingly blocked job (key `answer`) had not started.

So in this case the input job did not block the succeeding command steps `three` and `four`, but did block the `answer` job because it had a `depends_on` for one of the inputs. In the end, once the input was given the job did not become unblocked and resume.

For the next run I'm going to remove the `depends_on` from `answer`, but still try to print the value from the meta-data store (with a default value provided in case). I'm going to try and wait for this `answer` job to run before filling in the input.

I'll leave the concurrent agent changes investigation stuff for another run.
