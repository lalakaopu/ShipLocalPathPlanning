function draw_agent(agent, willVisualizeShipDomain)
%DRAW_AGENT Summary of this function goes here
%   Detailed explanation goes here

headingAngle = atan2(agent.velocity(2), agent.velocity(1)) ;
RfX = agent.position(1) + agent.Rf * cos(headingAngle) ;
RfY = agent.position(2) + agent.Rf * sin(headingAngle) ;
RaX = agent.position(1) - agent.Ra * cos(headingAngle) ;
RaY = agent.position(2) - agent.Ra * sin(headingAngle) ;
RpX = agent.position(1) - agent.Rp * sin(headingAngle) ;
RpY = agent.position(2) + agent.Rp * cos(headingAngle) ;
RsX = agent.position(1) + agent.Rs * sin(headingAngle) ;
RsY = agent.position(2) - agent.Rs * cos(headingAngle) ;

RX = [RfX, RpX, RaX, RsX, RfX] ;
RY = [RfY, RpY, RaY, RsY, RfY] ;

if willVisualizeShipDomain
    plot(RX, RY, 'b:', 'LineWidth', 1) ;
end

ellipse(agent.position(1), agent.position(2), agent.L/2, agent.B/2, atan2(agent.velocity(2), agent.velocity(1)), 'b') ;
end

