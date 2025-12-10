import argparse
import numpy as np
import pandas as pd
import warnings
from sklearn.model_selection import KFold, GroupKFold, GridSearchCV
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler

# Create an ArgumentParser object to handle command-line arguments
parser = argparse.ArgumentParser(description='Logistic regression, nested cross-validation with possible group-stratification')

# Add command-line arguments for dataset file and target column
parser.add_argument('dataset', type=str, help='Path to the CSV dataset file')
parser.add_argument('target_column', type=str, help='Name of the target column')
parser.add_argument('acc_out', type=str, help='TXT filename to save the accuracy')

# Add optional arguments for hyperparameter tuning, group column, and other options
parser.add_argument('--param_grid', type=str, default='C:0.0000001,0.000001,0.00001,0.0001,0.001,0.01,0.1,1,10,100',
                    help='Hyperparameter grid for tuning (format: parameter:values)')
parser.add_argument('--n_outer_splits', type=int, default=10,
                    help='Number of outer cross-validation splits')
parser.add_argument('--n_inner_splits', type=int, default=10,
                    help='Number of inner cross-validation splits')
parser.add_argument('--group_column', type=str, default=None,
                    help='Name of the group column (if not provided, group-based stratification is not used)')

# Parse the command-line arguments
args = parser.parse_args()


# Extract the dataset file path and target column name
csv_file = args.dataset
target_column_name = args.target_column

# Extract and parse the hyperparameter grid
param_grid_str = args.param_grid
param_grid = {}
for param_entry in param_grid_str.split('|'):
    param_name, param_values = param_entry.split(':')
    param_values = [float(val) if '.' in val else int(val) for val in param_values.split(',')]
    param_grid[param_name] = param_values


# Load your dataset and preprocess it as needed
data = pd.read_csv(csv_file)
y = data[target_column_name]  # Target variable
unique_y = data[target_column_name].nunique()

# check how many groups are there. set n_outer_splits to #groups if #groups < n_outer_splits
if args.group_column:
    unique_g = data[args.group_column].nunique()
    if args.n_outer_splits > unique_g:
        args.n_outer_splits = unique_g
        warnings.warn('Set outer-loop CV folds to number of groups because user-defined number of folds is larger than number of groups.')

outer_cv = GroupKFold(n_splits=args.n_outer_splits)
inner_cv = KFold(n_splits=args.n_inner_splits)

# Check if a group column is provided
if args.group_column:
    # custom group-based stratified cross-validation split
    groups = data[args.group_column]  # Group information
    X = data.drop([target_column_name, args.group_column], axis=1)  # Exclude target and group columns
    splits = outer_cv.split(X, y, groups=groups)
else:
    # Use standard stratified cross-validation without group-based stratification
    X = data.drop([target_column_name], axis=1)  # Exclude only the target column
    splits = outer_cv.split(X, y)

best_model = None
best_accuracy = 0

acc_sum = 0
for train_index, test_index in splits:
    X_train_outer, X_test_outer = X.iloc[train_index], X.iloc[test_index]
    y_train_outer, y_test_outer = y.iloc[train_index], y.iloc[test_index]
    scaler = StandardScaler().fit(X_train_outer)
    X_train_scaled = scaler.transform(X_train_outer)
    X_test_scaled = scaler.transform(X_test_outer)

    # Inner cross-validation for hyperparameter tuning
    grid_search = GridSearchCV(estimator=LogisticRegression(solver='sag', max_iter=1000), param_grid=param_grid, scoring='accuracy', cv=inner_cv)
    grid_search.fit(X_train_scaled, y_train_outer)

    # Get the best hyperparameters from inner CV
    best_hyperparameters = grid_search.best_params_

    # Train a model with the best hyperparameters on the full training set
    if(unique_y == 2):
        best_model = LogisticRegression(**best_hyperparameters, max_iter=100, solver='sag')
    else:
        best_model = LogisticRegression(**best_hyperparameters, multi_class='multinomial', max_iter=1000, solver='sag')
    best_model.fit(X_train_scaled, y_train_outer)
    y_train_pred = best_model.predict(X_train_scaled)
    acc_train = accuracy_score(y_train_outer, y_train_pred)
    print("Best Hyperparameters:", best_hyperparameters)
    print("Training Accuracy:", acc_train)

    # Evaluate the model on the outer test fold
    y_pred_outer = best_model.predict(X_test_scaled)
    accuracy = accuracy_score(y_test_outer, y_pred_outer)
    print("Test Accuracy:", accuracy)
    acc_sum = accuracy + acc_sum


print("Average Model Accuracy:", acc_sum/args.n_outer_splits)

with open(args.acc_out, 'w') as f:
    f.write(f"{acc_sum/args.n_outer_splits}")
