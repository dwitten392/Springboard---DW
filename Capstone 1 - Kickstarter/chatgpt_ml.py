import pandas as pd
import lightgbm as lgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, log_loss

# Load the dataset
file_path = 'kickstarter.csv'
data = pd.read_csv(file_path)

# Drop rows with missing values
data_cleaned = data.dropna(subset=['location.country', 'name'])

# Remove duplicate rows based on project ID
data_cleaned = data_cleaned.drop_duplicates(subset=['id'])

# Convert launched_at and deadline to datetime
data_cleaned['launched_at'] = pd.to_datetime(data_cleaned['launched_at'])
data_cleaned['deadline'] = pd.to_datetime(data_cleaned['deadline'])

# Filter out projects with a deadline date after the last project submitted
last_project_date = data_cleaned['deadline'].max()
data_cleaned = data_cleaned[data_cleaned['deadline'] <= last_project_date]

# Filter out projects with a goal of less than $1000
data_cleaned = data_cleaned[data_cleaned['goal'] >= 1000]

# Create new features
data_cleaned['total_days'] = (data_cleaned['deadline'] - data_cleaned['launched_at']).dt.days
data_cleaned['launch_month'] = data_cleaned['launched_at'].dt.month
data_cleaned['deadline_month'] = data_cleaned['deadline'].dt.month

# Convert categorical variables using one-hot encoding
categorical_columns = ['currency', 'location.country', 'category_name', 'location_type']
data_encoded = pd.get_dummies(data_cleaned, columns=categorical_columns, drop_first=True)

# Select relevant features for the model, excluding backers_count, goal_per_day, and days_to_deadline
features = ['goal', 'blurb_length', 'goal_USD', 'total_days', 'launch_month', 'deadline_month']
features += [col for col in data_encoded.columns if col.startswith('currency_')]
features += [col for col in data_encoded.columns if col.startswith('location.country_')]
features += [col for col in data_encoded.columns if col.startswith('category_name_')]

# Define the target variable
target = 'binary_state'

# Map the target variable to numerical values
data_encoded[target] = data_encoded[target].map({'successful': 1, 'failed': 0})

# Extract features and target variable from the dataset
X = data_encoded[features]
y = data_encoded[target]

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Create LightGBM dataset
train_data = lgb.Dataset(X_train, label=y_train)
test_data = lgb.Dataset(X_test, label=y_test, reference=train_data)

# Define parameters
params = {
    'objective': 'binary',
    'metric': ['binary_logloss', 'auc'],
    'boosting_type': 'gbdt',
    'num_leaves': 31,
    'learning_rate': 0.05,
    'feature_fraction': 0.9
}

# Train the model
bst = lgb.train(params, train_data, valid_sets=[train_data, test_data], num_boost_round=1000)

# Make predictions
y_pred_proba = bst.predict(X_test, num_iteration=bst.best_iteration)
y_pred = (y_pred_proba >= 0.5).astype(int)

# Evaluate the model
accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred)
recall = recall_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)
roc_auc = roc_auc_score(y_test, y_pred_proba)
log_loss_value = log_loss(y_test, y_pred_proba)

# Display the evaluation metrics
print(f'Accuracy: {accuracy}')
print(f'Precision: {precision}')
print(f'Recall: {recall}')
print(f'F1 Score: {f1}')
print(f'ROC-AUC Score: {roc_auc}')
print(f'Log-Loss: {log_loss_value}')
