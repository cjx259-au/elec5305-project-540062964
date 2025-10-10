function cfg = config()
cfg.seed = 5305;
cfg.R128_targetLUFS = -23;
cfg.R128_maxTP     = -1.0;
cfg.A85_targetLKFS = -24;
cfg.streamTargetLUFS = -14;

cfg.stWindow = 3.0;
cfg.mtWindow = 0.400;
cfg.blockSec = 0.400;
cfg.absGate  = -70;
cfg.relGate  = -10;
cfg.truePeakOversample = 4;

cfg.saveNormalized = false;
cfg.tpCeil = -1.0;
cfg.limiterKnee = 0.98;
end
