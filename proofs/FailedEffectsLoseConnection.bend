# proofs of laws/FailedEffectsLoseConnection.bend
import Base
import ../src/step.bend as Step
import ../laws/FailedEffectsLoseConnection.bend as Laws

def Laws.lost_failed(_a, _phase, _code, _why):
  {==}

def Laws.lost_kept(_a, _phase, _value):
  {==}

def Laws.lost_send(_code, _why, _left):
  {==}

def Laws.lost_sent(_done):
  {==}

def Laws.accept_idle(_a, _code, e, why):
  %e : {Step.step.missed(_a, why, _) == Step.Idle{} : Step.Accept<_a>}
  {==}

def Laws.accept_missed(_a, _code, e, why):
  %e : {Step.step.missed(_a, why, _) == Step.Missed{"ezhttp: accept: " ++ why}
    : Step.Accept<_a>}
  {==}

def Laws.accept_took(_a, _value):
  {==}
