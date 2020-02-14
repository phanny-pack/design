classdef ReactionControl < handle

properties (Access = public)
end

properties (Access = private)
    modes
    yawThrusters
    pitchThrusters
    rollThrusters
end

properties (SetAccess = private, GetAccess = public)
    resultant = [0 0 0 0 0 0]
    thrust
    arm
end

methods (Access = public)
    function self = ReactionControl(thrust, arm, yaw, pitch, roll)
        self.thrust = thrust;
        self.arm = arm;
        self.modes = struct('yaw', yaw, 'pitch', pitch, 'roll', roll);
        % TODO:: Add yaw and roll support for 6DOF system
        if (pitch)
            % If positive thruster fires, this produces a positive moment
            pThruster = ColdGasThruster(self.thrust);
            nThruster = ColdGasThruster(self.thrust);

            pThruster.place([0 0 arm], [1 0 0]);
            nThruster.place([0 0 arm], [-1 0 0]);

            self.pitchThrusters = [pThruster nThruster];
        end
    end

    function setCommands(self, U)
        % Assume commands of [Fx Fy Fz Mx My Mz] for generality
        if (self.modes.pitch)
            thrusterInput = U(1) + U(5) / self.arm;
            self.pitchThrusters(1).pwm.setCommand(0);
            self.pitchThrusters(2).pwm.setCommand(0);
            if (thrusterInput > 0); self.pitchThrusters(1).pwm.setCommand(thrusterInput);
            else; self.pitchThrusters(2).pwm.setCommand(thrusterInput);
            end
        end
    end

    function tick(self, dt)
        % Resultant of form [Fx Fy Fz Mx My Mz]
        self.resultant = zeros(1,6);
        for i = 1:2
            if self.modes.pitch
                self.pitchThrusters(i).tick(dt);
                if (self.pitchThrusters(i).pwm.output)
                    [F, M] = self.pitchThrusters(i).getForceOnThisTick();
                    self.resultant = self.resultant + [F' M'];
                end
            end
        end
    end

    function [F, M, y] = getForceOnThisTick(self)
        F = self.resultant(1:3);
        M = self.resultant(4:6);
        y = self.pitchThrusters(1).pwm.getY();
    end
end

end