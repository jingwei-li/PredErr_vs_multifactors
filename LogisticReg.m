function acc = LogisticReg(outdir, feature, target, group)

% acc = LogisticReg(outdir, feature, target, group)
%
% 
    
% Define input and output filenames
inputFilename = fullfile(outdir, 'input.txt');
outputFilename = fullfile(outdir, 'output.txt');
    
% write input data to the csv file
idx = isnan(feature) | cellfun(@isempty, target) | cellfun(@isempty, group);
feature = feature(~idx);
target = target(~idx);
group = group(~idx);
T = table(feature, target, group);
T.Properties.VariableNames = {'feature', 'target', 'group'};
writetable(T, inputFilename);
    
% Call the Python script with input and output filenames
script_dir = fileparts(mfilename('fullpath'));
scriptFilename = fullfile(script_dir, 'LogisticReg_covariates.py');
command = sprintf('python3 %s %s target %s --group_column group', scriptFilename, inputFilename, outputFilename);
status = system(command);
    
% Check the status of the execution
if status == 0
    disp('Python script executed successfully.');
    
    % Read the result from the output file
    acc = dlmread(outputFilename);
    delete(outputFilename)
else
    error('Error executing Python script.');
end
    
delete(inputFilename)
        
end