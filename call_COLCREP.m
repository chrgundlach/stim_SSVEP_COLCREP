%% call_COLCREP()
% first run the experiment with training, iso, main (starting from block 1)
Pbn = 99;
train = true;
iso = true;
startbl = 1;
RDK = run_COLCREP(Pbn,train,iso,startbl); % save RDK structure that is required for final part

%% run color categorization task
categ_set_YOG_PRPXX(Pbn,'propixx',RDK)