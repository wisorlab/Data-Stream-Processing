classdef mouse < handle
    properties
        
        % mouse primary information
        gender;
        filename;
        id;
        group;
        transgender;
        intensity;
        
        % mouse primary information as a cell array
%         data = {};
        
        % mouse secondary information
        trig = {};
        rand = {};
        
    end
    methods
        
        % constructor
        function this = mouse(row)
            cells = row.value;
%             this.data = cells{1:7};
            for i=8:numel(cells)
                value = cells{i};
                if isnan(value) && ~isempty(value)
                    break
                end
                this.trig{end+1} = value;
            end
            
            for j=i+1:numel(cells)
                value = cells{i};
                if isnan(value) && ~isempty(value)
                    break
                end
                this.rand{end+1} = value;
            end
        end
    end
end