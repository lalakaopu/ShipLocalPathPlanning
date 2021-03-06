%% Clear
clc; clear all; close all ;
addpath(genpath('agent'), genpath('obstacle'), genpath('ship_models'), genpath('function')) ;

%% Map condition
mapBoundary.xMin = 0 ;
mapBoundary.xMax = 600;
mapBoundary.yMin = -300 ;
mapBoundary.yMax = 300 ;
figure_scale = 2/3 ;

%% Initial agent
agent = Agent() ;
agent.model = WMAV2016() ;
agent.position = [0 ;   % x(m)
                 0 ;    % y(m)
                 0] ;     % psi(rad)
agent.velocity = [2 ;   % u(m/s)
                  0 ;   % v(m/s)
                  0] ;  % r(rad/s)
% agent.radius = 5 ;    % (m)

%% Initial obstacles
obstacles.obstacle1 = Obstacle() ;
obstacles.obstacle1.position = [150 ;     % x(m)
                                300] ;   % y(m)
obstacles.obstacle1.velocity = [0 ;     % x(m)
                                -3] ;   % y(m)
obstacles.obstacle1.radius = 10 ;

% obstacles.obstacle2 = Obstacle() ;
% obstacles.obstacle2.position = [200 ;    % x(m)
%                                 -900] ;   % y(m)
% obstacles.obstacle2.velocity = [0 ;   % x(m)    
%                                 8.5] ; % y(m)      
% obstacles.obstacle2.radius = 12 ;
% 
% obstacles.obstacle3 = Obstacle() ;
% obstacles.obstacle3.position = [300 ;    % x(m)
%                                 1500] ;   % y(m)
% obstacles.obstacle3.velocity = [0 ;   % x(m)    
%                                 -8.5] ; % y(m)     
% obstacles.obstacle3.radius = 12 ;
% % 
% obstacles.obstacle4 = Obstacle() ;
% obstacles.obstacle4.position = [100 ;     % x(m)
%                                 -100] ;   % y(m)
% obstacles.obstacle4.velocity = [0 ;     % x(m)
%                                 1] ;   % y(m)
% obstacles.obstacle4.radius = 5 ;
% 
% obstacles.obstacle5 = Obstacle() ;
% obstacles.obstacle5.position = [200 ;    % x(m)
%                                 -100] ;   % y(m)
% obstacles.obstacle5.velocity = [0 ;   % x(m)    
%                                 1] ; % y(m)      
% obstacles.obstacle5.radius = 5 ;
% 
% obstacles.obstacle6 = Obstacle() ;
% obstacles.obstacle6.position = [300 ;    % x(m)
%                                 -100] ;   % y(m)
% obstacles.obstacle6.velocity = [0 ;   % x(m)    
%                                 1] ; % y(m)     
% obstacles.obstacle6.radius = 5 ;


obstacleTurningRate = 3 * (pi / 180) ;
obstacleTurningAngle = 0 ;

obstacleNames = fieldnames(obstacles) ;

%% Time horizon
timeHorizon = 60;

%% Mission of agent
N_line_grid = 5 ;
targetLineX = linspace(mapBoundary.xMin, mapBoundary.xMax, N_line_grid)' ;
targetLineY = linspace(0, 0, N_line_grid)' ;
targetLine = [targetLineX, targetLineY] ;
% targetPoint = [0, 30] ;

%% Visualization setting
willVisualizeVelocityObstacle = false ;
willVisualizeReachableVelocities = false ;
willVisualizeReachableAvoidanceVocities = false ;
willVisualizeShipDomain = false ;
willVisualizeVelocityVector = false ;

willWriteClock = false ;
willWriteSpeed = false ;

checkTime = 50 ;

%% Initial condition for simulation
isCrashed = false ;
firstTurningRecorded = false ;

time = 0 ;
global dt
dt = 1 ;

timeHistory = [] ;
timeStringHistory = {'0 sec'} ;
speedHistory = [] ;
relativeDistanceHistory = [] ;
courseAngleHistory = [] ;

agentPositionHistory1 = agent.position ;
agentPositionHistory2 = agent.position ;
for obstacleIndex = 1:numel(obstacleNames)
    obstaclePositionHistory1{obstacleIndex} = obstacles.(obstacleNames{obstacleIndex}).position ;
    obstaclePositionHistory2{obstacleIndex} = obstacles.(obstacleNames{obstacleIndex}).position ;
end

%% Visualization
fontSize = 7 ;

% Figure for simlulation
simulationFigure = figure(1) ;
figure1_position = [-1700, 100] ;
figure1_size = [(mapBoundary.xMax - mapBoundary.xMin),...
               (mapBoundary.yMax - mapBoundary.yMin)] * figure_scale ;
simulationFigure.Position = [figure1_position, figure1_size] ;
set(gca, 'FontSize', fontSize) ;
daspect([1 1 1])
grid on ;
axis([mapBoundary.xMin, mapBoundary.xMax, mapBoundary.yMin, mapBoundary.yMax]) ;
xlabel('x(m)') ;
ylabel('y(m)') ;
box on ;

% Figure for zoom in
zoomInFigure = figure(2) ;
figure2_position = figure1_position + [round(mapBoundary.xMax * figure_scale) + 1, 0] ;
figure2_size = [(mapBoundary.xMax - mapBoundary.xMin),...
               (mapBoundary.yMax - mapBoundary.yMin)] * figure_scale ;
zoomInFigure.Position = [figure2_position, figure2_size] ;
daspect([1 1 1])
xlabel('x(m)') ;
ylabel('y(m)') ;
box on ;

% Figure for plotting speed
speedHistoryFigure = figure(3) ;
figure3_position = figure2_position + [round(mapBoundary.xMax * figure_scale) + 1, 0] ;
figure3_size = [(mapBoundary.xMax - mapBoundary.xMin),...
               (mapBoundary.yMax - mapBoundary.yMin)] * figure_scale;
speedHistoryFigure.Position = [figure3_position, figure3_size] ;
box on ;

% Figure for plotting relative distance
relativeDistanceHistoryFigure = figure(4) ;
figure4_position = figure3_position + [round(mapBoundary.xMax * figure_scale) + 1, 0] ;
figure4_size = [(mapBoundary.xMax - mapBoundary.xMin),...
               (mapBoundary.yMax - mapBoundary.yMin)] * figure_scale;
relativeDistanceHistoryFigure.Position = [figure4_position, figure4_size] ;
box on ;

% Figure for plotting course angle
courseAngleHistoryFigure = figure(5) ;
figure5_position = figure4_position + [round(mapBoundary.xMax * figure_scale) + 1, 0] ;
figure5_size = [(mapBoundary.xMax - mapBoundary.xMin),...
               (mapBoundary.yMax - mapBoundary.yMin)] * figure_scale;
courseAngleHistoryFigure.Position = [figure5_position, figure5_size] ;
box on ;
           
           
%% Simulation
while mapBoundary.xMin <= agent.position(1) && agent.position(1) <= mapBoundary.xMax ...
        && mapBoundary.yMin <= agent.position(2) && agent.position(2) <= mapBoundary.yMax
    
    figure(1) ;
    
    %   Clear the axes
    cla(simulationFigure) ;
    
%     figure(1) ;
    hold on ;
%     if time == 0
%         disp('Press enter to start') ;
%         pause() ;
%     end
    
%     figure(1) ;
    %   Draw the reference line
    plot(targetLine(:, 1), targetLine(:, 2), 'g', 'LineWidth', 3) ;
    %{
    plot(targetPoint(1), targetPoint(2), 'v') ;
    %}
    
    %% Record
    % Write clock
    time = time + dt ;
    if willWriteClock
        timeString = ['Time: ', num2str(time), ' s'] ;
        text(mapBoundary.xMin + 2, mapBoundary.yMax - 8*(1/figure_scale), timeString) ;
    end
    timeHistory(end + 1) = time ;    
    
    % Write speed
    speed = round(sqrt(agent.velocity(1)^2 + agent.velocity(2)^2)/dt, 3, 'significant') ;
    if willWriteSpeed
        speedString = ['Speed: ', num2str(speed), ' m/s'] ;
        text(mapBoundary.xMin + 2, mapBoundary.yMax - 24*(1/figure_scale), speedString) ;
    end
    speedHistory(end + 1) = speed ;
    
    % Relative distance
    for obstacleIndex = 1:numel(fieldnames(obstacles))
        relativeDistance(obstacleIndex) =...
            pdist([agent.position(1:2)'; 
                   obstacles.(obstacleNames{obstacleIndex}).position(1:2)'])...
                   - agent.L - obstacles.(obstacleNames{obstacleIndex}).radius;
    end
    relativeDistanceHistory(end + 1, :) = relativeDistance ;

    % Course angle
    courseAngleHistory(end + 1) = agent.position(3) ;
    
    % Values at turning start time
    if firstTurningRecorded == false && (agent.position(3) < -5*pi/180 || agent.position(3) > 5*pi/180)
        fprintf('Turning start time: %4.2f sec\n', time) ;
        fprintf('Relative distance at turning start time: %4.2f m\n', relativeDistance) ;
        firstTurningRecorded = true ;
    end
    
    %% Obstacle course change
    % [obstacle moving case 1] for crossing situation with target ship from port 
%     if 50 <= time && time < 70
%         obstacleTurningAngle = obstacleTurningAngle + obstacleTurningRate ;
%         obstacleSpeed = sqrt(obstacles.obstacle1.velocity(1)^2 + obstacles.obstacle1.velocity(2)^2) ;
%         obstacles.obstacle1.velocity = obstacleSpeed...
%                                         * [-sin(obstacleTurningAngle);
%                                            -cos(obstacleTurningAngle)] ;
%     elseif 80 <= time && time < 100
%         obstacleTurningAngle = obstacleTurningAngle - obstacleTurningRate ;
%         obstacleSpeed = sqrt(obstacles.obstacle1.velocity(1)^2 + obstacles.obstacle1.velocity(2)^2) ;
%         obstacles.obstacle1.velocity = obstacleSpeed...
%                                         * [-sin(obstacleTurningAngle);
%                                            -cos(obstacleTurningAngle)] ;
%     end
    
    % [obstacle moving case 2] for head-on situation with arbitrary target ship
%     if 115 <= time && time < 125
%         obstacleTurningAngle = obstacleTurningAngle + obstacleTurningRate ;
%         obstacleSpeed = sqrt(obstacles.obstacle1.velocity(1)^2 + obstacles.obstacle1.velocity(2)^2) ;
%         obstacles.obstacle1.velocity = obstacleSpeed...
%                                         * [-cos(obstacleTurningAngle);
%                                            -sin(obstacleTurningAngle)] ;
%     end
    
%     elseif 140 <= time && time < 160
%         obstacleTurningAngle = obstacleTurningAngle - obstacleTurningRate ;
%         obstacleSpeed = sqrt(obstacles.obstacle1.velocity(1)^2 + obstacles.obstacle1.velocity(2)^2) ;
%         obstacles.obstacle1.velocity = obstacleSpeed...
%                                         * [-sin(obstacleTurningAngle);
%                                            -cos(obstacleTurningAngle)] ;
%    elseif 130 <= time && time < 140
%         obstacleTurningAngle = obstacleTurningAngle + obstacleTurningRate ;
%         obstacleSpeed = sqrt(obstacles.obstacle1.velocity(1)^2 + obstacles.obstacle1.velocity(2)^2) ;
%         obstacles.obstacle1.velocity = obstacleSpeed...
%                                         * [sin(obstacleTurningAngle);
%                                            -cos(obstacleTurningAngle)] ;
%     end

%     if time > 180
%         obstacles.obstacle1.velocity = [-1.2 ;   % x(m)
%                                         0] ; % y(m)
%     end
%     if time > 100
%         obstacles.obstacle3.velocity = [-2 ;   % x(m)
%                                         0] ; % y(m)
%     end
%     if time > 130
%         obstacles.obstacle3.velocity = [-1.3 ;   % x(m)
%                                         -1.3] ; % y(m)
%     end
    
    %% Update ship domain
    agent.update_ship_domain() ;
    
    %% Proceed to next step
    % Calculate Collision Cone
    collisionConePoints = collision_cone(agent, obstacles, timeHorizon) ;
    
    %% Calculate velocity obstacle from Collision Cone
    for obstacleIndex = 1:numel(fieldnames(obstacles))
        velocityObstaclePoints{obstacleIndex} = ...
            collisionConePoints{obstacleIndex} + ...
            obstacles.(obstacleNames{obstacleIndex}).velocity(1:2)' ;
    end
    
    %% Draw velocity obstacle
    if willVisualizeVelocityObstacle
        for j = 1:numel(fieldnames(obstacles))
            if isreal(velocityObstaclePoints{j})
                fill(velocityObstaclePoints{j}(:, 1), velocityObstaclePoints{j}(:, 2), 'y') ;
                alpha(0.1) ;
            end
        end
    end
    
    %% Calculate feasible accelearation
    agent.feasible_acceleration() ;
        
    %% Calculate reachable velocities of agent
    agent.reachableVelocities = (agent.velocity + dt * agent.feasibleAcceleration) * (1) ;
    
    %% Draw reachable velocites
    shiftedReachableVelocities = agent.position + agent.reachableVelocities ;
    if willVisualizeReachableVelocities
        k = convhull(shiftedReachableVelocities(1, :),...
            shiftedReachableVelocities(2, :)) ;
        patch('Faces', 1:1:length(k),...
            'Vertices',...
            [shiftedReachableVelocities(1, k);...
            shiftedReachableVelocities(2, k)]',...
            'FaceColor', 'g', 'FaceAlpha', .1) ;
    end
    
    %% Calculate reachable avoidance velocities
    for m = 1:numel(fieldnames(obstacles))
        in = inpolygon(shiftedReachableVelocities(1, :), shiftedReachableVelocities(2, :),...
            velocityObstaclePoints{m}(:, 1), velocityObstaclePoints{m}(:, 2)) ;
        inSet(:, m) = in ;
    end
    
    % Judge the reachable velocities ovelapped to collision cone
    hasAllOverlap = false ;
    hasPartialOverlap = false ;
    
    if all(any(inSet, 2))
        hasAllOverlap = true ;
    elseif any(any(inSet, 2))
        hasPartialOverlap = true ;
    end
    
    in = any(inSet, 2) ;
    
    shiftedReachableAvoidanceVelocitiesOut = shiftedReachableVelocities(:, ~in) ;
    reachableVelocities = shiftedReachableVelocities - agent.position ;
    reachableAvoidanceVelocitiesOut = shiftedReachableAvoidanceVelocitiesOut - agent.position ;
    
%     if isempty(reachableAvoidanceVelocities)
%         text(mapBoundary.xMin, (mapBoundary.yMin + mapBoundary.yMax) / 2, ...
%             'Nothing reachable avoidance velocities', 'FontSize', 20, 'Color', 'r') ;
%         break
%     end
    
    %% Draw reachable avoidance velocities
    if willVisualizeReachableAvoidanceVocities
        plot(shiftedReachableAvoidanceVelocitiesOut(1, :),...
            shiftedReachableAvoidanceVelocitiesOut(2, :), 'm.') ;
    end
  
    %% Draw agent and obstacle position
    draw_agent(agent, willVisualizeShipDomain) ;
    draw_obstacle(obstacles) ;
    
    %   Draw trajectory of agent and obstacles
    if mod(time, 1) == 0
        agentPositionHistory1(:, end + 1) = agent.position ;
        for obstacleIndex = 1:numel(obstacleNames)
            obstaclePositionHistory1{obstacleIndex}(:, end + 1) =...
                obstacles.(obstacleNames{obstacleIndex}).position ;
        end
    end
    agentTrajectoryPlot = plot(agentPositionHistory1(1, :), agentPositionHistory1(2, :), '-b', 'LineWidth', 1) ;
    
    for obstacleIndex = 1:numel(obstacleNames)
        obstacleTrajectoryPlot = plot(obstaclePositionHistory1{obstacleIndex}(1, :),...
                                obstaclePositionHistory1{obstacleIndex}(2, :), '--r', 'LineWidth', 1) ;
    end
    
    %   Draw time at corresponding position of agent and obstacles
    if mod(time, checkTime) == 0
        agentPositionHistory2(:, end + 1) = agent.position ;
        for obstacleIndex = 1:numel(obstacleNames)
            obstaclePositionHistory2{obstacleIndex}(:, end + 1) =...
                obstacles.(obstacleNames{obstacleIndex}).position ;
        end
        timeStringHistory{end + 1} = [num2str(time), ' sec'] ;
    end
    
    for timeTextIndex = 1:length(timeStringHistory)
        plot(agentPositionHistory2(1, :), agentPositionHistory2(2, :), 'b.', 'MarkerSize', 20) ;
        text(agentPositionHistory2(1, timeTextIndex)-10,...
            agentPositionHistory2(2, timeTextIndex)-10,...
            timeStringHistory{timeTextIndex},...
            'FontSize', fontSize) ;
        for obstacleIndex = 1:numel(obstacleNames)
            plot(obstaclePositionHistory2{obstacleIndex}(1, :),...
                obstaclePositionHistory2{obstacleIndex}(2, :), 'ro', 'MarkerSize', 5) ;
            text(obstaclePositionHistory2{obstacleIndex}(1, timeTextIndex)-10,...
                obstaclePositionHistory2{obstacleIndex}(2, timeTextIndex)+15,...
                timeStringHistory{timeTextIndex},...
                'FontSize', fontSize) ;
        end
    end
        
    %% Velocity strategy: to target point
    %{
    distanceToTarget = [] ;
    for l = 1:length(shiftedReachableAvoidanceVelocities)
        distanceToTarget(l, :) =...
            pdist([shiftedReachableAvoidanceVelocities(l, :); targetPoint]) ;
    end
    [~, ChosenVelocityIndex] = min(distanceToTarget) ;
    %}
    
    %% Velocity strategy: if nowhere the agent can avoid collsion, it just stops
    if hasAllOverlap  
%         [~, minIndex] = min(abs(sqrt(reachableVelocities(1, :).^2 + reachableVelocities(2, :).^2))) ;     % stay
        [~, minIndex] = min(reachableVelocities(1, :)) ;       % step back
%         [~, minIndex] = max(reachableVelocities(2, :)) ;       % go around to left
%         [~, minIndex] = min(reachableVelocities(2, :)) ;       % try its' best to comply with COLREGS
        ChosenVelocityIndex = minIndex ;
        agent.velocity = reachableVelocities(:, ChosenVelocityIndex) ;
    %% Velocity strategy: comply with COLREGS
    elseif hasPartialOverlap
        [~, minIndex] = min(shiftedReachableAvoidanceVelocitiesOut(2, :)) ;
        ChosenVelocityIndex = minIndex ;
        agent.velocity = reachableAvoidanceVelocitiesOut(:, ChosenVelocityIndex) ;     % Cosse velocity
    else
    %% Velocity strategy: to target line
        [~, maxIndex] = maxk(shiftedReachableAvoidanceVelocitiesOut(1, :),...
            round(length(shiftedReachableAvoidanceVelocitiesOut) / (6) + 1)) ;
        [~, minIndexOfMaxIndex] = min(abs(shiftedReachableAvoidanceVelocitiesOut(2, maxIndex))) ;
        ChosenVelocityIndex = maxIndex(minIndexOfMaxIndex) ;
        agent.velocity = reachableAvoidanceVelocitiesOut(:, ChosenVelocityIndex) ;     % Choose velocity

    end
%     [~, idx_nu] = min(abs(shiftedReachableAvoidanceVelocities(2, :))) ;
%     ChosenVelocityIndex = idx_nu ;

%     [~, idx_nu] = max((shiftedReachableAvoidanceVelocities(1, :))) ;
%     ChosenVelocityIndex = idx_nu ;
%     

    
    %% Draw the veloity vector of agent and obstacle
    if willVisualizeVelocityVector
        %   Velocity vector of agent
        quiver(agent.position(1), agent.position(2),...
            agent.velocity(1), agent.velocity(2), 0,...
            'Color', 'b', 'LineWidth', 1) ;

        %   Velocity vector of obstacles
        for o = 1:numel(fieldnames(obstacles))
            quiver(obstacles.(obstacleNames{o}).position(1), obstacles.(obstacleNames{o}).position(2),...
                obstacles.(obstacleNames{o}).velocity(1), obstacles.(obstacleNames{o}).velocity(2), 0,...
                'Color', 'r', 'LineWidth', 1) ;
        end
    end
   
    %% Additional figure for reachable velocity vectors
    figure(2) ;
    axis([agent.position(1)-20, agent.position(1)+20, agent.position(2)-20, agent.position(2)+20]) ;
    
    cla ;
    hold on ;
    grid on ;
    
    % Draw the reference line
    plot(targetLine(:, 1), targetLine(:, 2), 'g', 'LineWidth', 3) ;
    
    % Draw agent
    plot(agent.position(1), agent.position(2), 'b.', 'MarkerSize', 20) ;
    draw_agent(agent, willVisualizeShipDomain) ;
    
    % Draw obstacles
    draw_obstacle(obstacles) ;
    
    % Draw velocity obstacle
    if willVisualizeVelocityObstacle
        for j = 1:numel(fieldnames(obstacles))
            if isreal(velocityObstaclePoints{j})
                fill(velocityObstaclePoints{j}(:, 1), velocityObstaclePoints{j}(:, 2), 'y') ;
                alpha(0.1) ;
            end
        end
    end
    
    % Draw reachable velocites
    if willVisualizeReachableVelocities
        k = convhull(shiftedReachableVelocities(1, :),...
            shiftedReachableVelocities(2, :)) ;
        patch('Faces', 1:1:length(k),...
            'Vertices',...
            [shiftedReachableVelocities(1, k);...
            shiftedReachableVelocities(2, k)]',...
            'FaceColor', 'g', 'FaceAlpha', .1) ;
    end
    
    % Draw reachable avoidance velocities
    if willVisualizeReachableAvoidanceVocities
        plot(shiftedReachableAvoidanceVelocitiesOut(1, :),...
            shiftedReachableAvoidanceVelocitiesOut(2, :), 'm.') ;
    end
    
    % Draw the veloity vector of agent and obstacle
    if willVisualizeVelocityVector
        %   Velocity vector of agent
        quiver(agent.position(1), agent.position(2),...
            agent.velocity(1), agent.velocity(2), 0,...
            'Color', 'b', 'LineWidth', 1) ;
    end
    
    %% Crash
    for q = 1:numel(fieldnames(obstacles))
        if pdist([agent.position(1:2)'; obstacles.(obstacleNames{q}).position(1:2)']) <= ...
                agent.radius + obstacles.(obstacleNames{q}).radius 
%            figure(1) ; 
%            text(mapBoundary.xMax - 70, mapBoundary.yMin + 10,...
%                 'Crashed', 'Color', 'red', 'FontSize', 20) ;
           isCrashed = true ;
        end
    end
    if isCrashed
        break
    end
    
    %% Udpate the rpm the ship took
    agent.update_rpm(ChosenVelocityIndex)
    
    %% Calculate next position
    agent.setNextPosition() ;
    for p = 1:numel(fieldnames(obstacles))
        obstacles.(obstacleNames{p}).setNextPosition(dt) ;
    end
    
    

    
end

%% Save the result
windowForSmooth = 30 ;
graphRatio = [4 0.4 0.4] ;

% Trajectory
saveas(simulationFigure, 'trajectoryResult.png') ;

% Speed
figure(3) ;
plot(timeHistory, smoothdata(speedHistory, 'gaussian', windowForSmooth), 'LineWidth', 1) ;
set(gca, 'Xlim', [min(timeHistory) max(timeHistory)],...
         'YLim', [0 3],...
         'FontSize', fontSize) ;
grid on ;
pbaspect(graphRatio)
xlabel('Time (sec)') ;
ylabel('Speed (m/s)') 
saveas(speedHistoryFigure, 'speedResult.png') ;

% Relative distance
figure(4) ;
lineStyle = {'-', '--', '-.'} ;
for obstacleIndex = 1:numel(fieldnames(obstacles))
    hold on ;
    
    plot(timeHistory,...
         smoothdata(relativeDistanceHistory(:, obstacleIndex), 'gaussian', windowForSmooth),...
         lineStyle{obstacleIndex},...
         'LineWidth', 1) ;
    fprintf('Minimum relatvie distance: %4.2f m\n', min(smoothdata(relativeDistanceHistory(:, obstacleIndex), 'gaussian', windowForSmooth))) ;
end
hold off ;
set(gca, 'Xlim', [min(timeHistory) max(timeHistory)],...
         'YLim', [0 600],...
         'FontSize', fontSize) ;
grid on ;
pbaspect(graphRatio)
xlabel('Time (sec)') ;
ylabel('Relative distance (m)') 
saveas(relativeDistanceHistoryFigure, 'relativeDistanceResult.png') ;

% Course angle
figure(5) ;
yLimit = max([abs(min(smoothdata(courseAngleHistory*180/pi, 'gaussian', windowForSmooth))),...
              abs(max(smoothdata(courseAngleHistory*180/pi, 'gaussian', windowForSmooth)))]) ;
plot(timeHistory,...
     smoothdata(courseAngleHistory*180/pi, 'gaussian', windowForSmooth),...
     'LineWidth', 1) ;
set(gca, 'Xlim', [min(timeHistory) max(timeHistory)],...
         'YLim', [-yLimit*1.2 yLimit*1.2],... 
         'FontSize', fontSize) ;
grid on ;
pbaspect(graphRatio)
xlabel('Time (sec)') ;
ylabel('Course angle (deg)') 
saveas(courseAngleHistoryFigure, 'courseAngle.png') ;