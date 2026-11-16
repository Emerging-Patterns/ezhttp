# For every slots channel, `max`, done channel and tracking, the pool a
# serve hands its forks (`step.pool`) is limited exactly when `max` is not
# 0, so `max` 0 is no concurrency limit, and a limited serve joins its forks
# on the done channel it made the pool with. What the forks do with the pool
# is effects (trusted in src/server.bend).
import Base
import ../src/step.bend as Step

# LAW: a pool is limited exactly when max is not 0
law pool_limited:
  for slots: Chan(Unit)
  for +max: U32
  for done: Chan(Unit)
  for tracked: Bool
  {Step.step.pool.limited(Step.step.pool(slots, max, done, tracked))
    == U32.is_ne(max, 0) : Bool}

# LAW: a pool's forks say they are done on the channel it was made with
law pool_done:
  for slots: Chan(Unit)
  for +max: U32
  for done: Chan(Unit)
  for tracked: Bool
  {Step.step.pool.done(Step.step.pool(slots, max, done, tracked))
    == done : Chan(Unit)}
