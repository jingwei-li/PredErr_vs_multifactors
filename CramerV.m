function V = CramerV(outdir, varA, varB)

% V = CramerV(outdir, varA, varB)
%
% 
    
% Define input and output filenames
inputFilename = fullfile(outdir, 'input.txt');
outputFilename = fullfile(outdir, 'output.txt');
    
% Write the categorical variables to the input file
fileID = fopen(inputFilename, 'w');
fprintf(fileID, '%s\n', 'Category_A');
fprintf(fileID, '%s\n', strjoin(varA, ','));
fprintf(fileID, '%s\n', 'Category_B');
fprintf(fileID, '%s\n', strjoin(varB, ','));
fclose(fileID);
    
% Call the R script with input and output filenames
script_dir = fileparts(mfilename('fullpath'));
rScriptFilename = fullfile(script_dir, 'CramerV_covariates.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, inputFilename, outputFilename);
status = system(command);
    
% Check the status of the execution
if status == 0
    disp('R script executed successfully.');
    
    % Read the result from the output file
    V = dlmread(outputFilename);
    delete(outputFilename)
else
    error('Error executing R script.');
end
    
delete(inputFilename)
end