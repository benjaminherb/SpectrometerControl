function values = get_values(type, steps)
% returns R,G,B values

i = 1;
for r = 0:1/steps:1
    for g = 0:1/steps:1
        for b = 0:1/steps:1
            valid_value = 0;

            switch type
                case "borders"
                    valid_value = ...
                        ((r == 0 || r == 1) && g == b) || ...
                        ((g == 0 || g == 1) && r == b) || ...
                        ((b == 0 || b == 1) && r == g) || ...
                        ((r == 0 || r == 1) && (g == 0 || g == 1)) || ...
                        ((r == 0 || r == 1) && (b == 0 || b == 1)) || ...
                        ((b == 0 || b == 1) && (g == 0 || g == 1));
                    
                case "primary-borders"
                    valid_value = ...
                        ((g == 0) && (b == 0)) ||  ...
                        ((r == 0) && (b == 0)) ||  ...
                        ((g == 0) && (r == 0)) || ...
                        ((r == 1) && (g == b)) || ...
                        ((g == 1) && (r == b)) || ...
                        ((b == 1) && (r == g));
                    
                case "mesh"
                    valid_value = (r == 0 || r == 1 || g == 0 || g == 1 || b == 0 || b == 1);
                               
                case "grey"
                    valid_value = (r == g && r == b && g == b);
                otherwise
                    disp("Invalid option '" + type + "'!");
                    return
            end
            
            if valid_value
                values(i,1:3) = [r, g, b];
                i = i+1;
            end
        end
    end
end
end