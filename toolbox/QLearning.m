function [Q,BufferSeq,HoldingSeq,OverflowSeq,PowerSeq,CostSeq,MuSeq] = QLearning(state,action,bufferStates,channelStates,cardStates,BEPActions,cardActions,throughputActions, initialState, RequiredPower,OverflowCost,BufferCost,HoldingCost,delayConstraint,niter,dynamics_s,gamma)
% Performs classic Q Learning on the problem
% Inputs
%   bufferStates:           possible states of the buffer
%   channelStates:          possible states of the channel
%   cardStates:             possible states of the wireless card
%   BEPActions:             possible values for BEP
%   cardActions:            possible dynamic power management actions
%   throughputActions:      possible values for the throughput
%   initialState:           initialState of the system
%   cost:                   lagrangian cost constraint
% Outputs
%   Q:                      optimized state action value function

disp('Start Q Learning...');

% Initialization
NumStates = length(bufferStates)*length(channelStates)*length(cardStates);
NumActions = length(BEPActions)*length(cardActions)*length(throughputActions);
Q = zeros(NumStates,NumActions);
currentState = state(initialState(1),initialState(2), initialState(3));
mu=0.1;
BufferSeq = zeros(1,niter);
HoldingSeq = zeros(1,niter);
OverflowSeq = zeros(1,niter);
PowerSeq = zeros(1,niter);
CostSeq = zeros(1,niter);
MuSeq = zeros(1,niter);
BufferCost = reshape(BufferCost,[NumStates, NumActions]);
HoldingCost = reshape(HoldingCost,[NumStates,NumActions]);
OverflowCost = reshape(OverflowCost,[NumStates,NumActions]);
RequiredPower = reshape(RequiredPower,[NumStates,NumActions]);
alpha = ones(NumStates,NumActions);

for t=1:niter
    % Pick an action
    [~,indAction] = min(Q(currentState,:));
    if(rand() > 0.9)
        greedy = randperm(NumActions);
        indAction = greedy(1);
    end
    % Next state
    NextState = simu_s(dynamics_s,currentState,indAction);
    % Observe costs
    [currentIndBuffer,currentIndChannel,currentIndCard] = ind2sub(size(state),currentState);
    [currentBEP,currentDPM,currentZ] = ind2sub(size(action),indAction);
    currentBufferCost = BufferCost(currentState,indAction);
    currentHoldingCost = HoldingCost(currentState,indAction);
    currentOverflowCost = OverflowCost(currentState,indAction);
    currentRequiredPower = RequiredPower(currentState,indAction);
    currentCost = currentRequiredPower + mu*currentBufferCost;
    
    BufferSeq(t) = currentBufferCost;
    HoldingSeq(t) = currentHoldingCost;
    OverflowSeq(t) = currentOverflowCost;
    PowerSeq(t) = currentRequiredPower;
    CostSeq(t) = currentCost;
    % Reward
    reward = currentCost;
    % Update Q
    Q(currentState,indAction) = Q(currentState,indAction) + (1/alpha(currentState,indAction))*(reward + gamma*min(Q(NextState,:)) - Q(currentState,indAction));
    % Update state
    currentState = NextState;
    alpha(currentState,indAction) = alpha(currentState,indAction) + 1;
end                   
end

