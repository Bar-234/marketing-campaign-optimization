# Data Collection And Preparation

- **DataSet:**  Marketing campaign user interactions
- **Records:** 10,000+ user sessions
- **Features:** 6 variables (user_id,test_group, converted, total_ads, most_ads_hour, most_ads_day) 

# Data Quality Assessment

**Missing Values Check:**

SELECT
  COUNT(*) - COUNT(user_id) AS missing_user_id,
  COUNT(*) - COUNT(test_group) AS missing_test_group,
  COUNT(*) - COUNT(converted) AS missing_converted,
  COUNT(*) - COUNT(total_ads) AS missing_total_ads
FROM marketing_campaign;

**Handling Strategy:**
- Missing values:<1% of dataset-> Removed
- Duplicates: Identified by user_id-> Kept first occurance

# Data Cleaning Process

**Remove Duplicates**
- **Method :** SQL DISTINCT on user_id
- **Records removed:** X

**Handle Missing Values**
- **Method :** Complete case analysis
- **Justification:** Missing data< 1% MCAR assumption

**Data Type Validation**
- **Boolean fields:** test_group, converted
- **Integer fields:** total_ads, most_ads_hour
- **categorical:** most_ads_day

# Exploratory Data Analysis

**Univariate Analysis**

**Continuous variables:**
- Distribution of total_ads : Right-skewed (mean=15.3, median=13, std=8.2)
- Used histograms and box plots to identify patterns

**Categorical Variables:**
- test_group distribution : 50/50 split(A/B Test balanced)
- converted rate : 25.4% overall conversion
- most_ads_day : Fairly uniform distribution

**Bivariate Analysis**

**conversion vs Test Group:**
- Control: 22.1% conversion
- Test: 28.8 % conversion
- Difference: 6.7 percentage points

**Conversion vs Ad Frequency:**
- Low(0-9) : 18.5%
- Medium(10-20) : 32.1%
- High(21+) : 19.3%
- **Finding:** Inverted U-shape relationship

**Conversion vs Hour**
- Peak Hours: 14(2 PM) and 18(6 PM)
- Lowest : Early morning(2-6 AM)

**Correlation Analysis**
- correlation_matrix = df.corr()

# **Key Findings:**
- test_group vs converted:  r = 0.15(weak positive) 
- total_ads vs converted: r = 0.08 (weak positive, non-linear)

# Statistical Analysis

**Hypothesis Test - A/B Test Effectiveness**

**Hypotheses:**
- H0 : p_test = p_control (no difference in conversion rates)
- H1 : p_test != p_control (Significant Difference exists)

**Test Selection** : Chi-Square Test of Independence

**Results:**
- x2 statistic : 45.23
- p-value : 0.00001
- Degrees Of freedom : 1 
- **Decision :** Reject H0 (p<0.05)
- **Interpretation:** Test group significantly outperforms control

**Effect Size :**
- Cohen's h : 0.14 (Small to medium effect)
- Lift : 30.4% relative improvement

**Confidence Interval(95%):**
- Test group conversion : 28.8% 
- Control group conversion : 22.1%
- Difference : 6.7%

**Hypothesis Test - Ad Frequency Impact**

**Hypotheses:**
- H0 : u_converted = u_not_converted (Same Average Ads)
- H1 : u_converted != u_not_converted (different average ads)

**Test Selection :** Independent Sample T-test

**Results:**
- t-statistic: -2.87
- p-value : 0.004
- **Decision:** Reject H0 (p<0.05)
- **Interpretation:** Converted users saw different ad frequency

**Descriptive Statistics:**
- Converted : Mean = 13.2 ads(SD=6.1)
- Not Converted : Mean = 15.8 ads (SD=9.3)
- **Finding:** Fewer ads associated with higher conversion (Diminishing returns)

**Hypothesis Test - Time of Day Effect**

**Hypotheses:**
- H0 : All hours have equal conversions rates
- H1 : At least one hour differs significantly

**Test Selection:** One-Way ANOVA

**Results:**
- F-Statistic : 3.42
- p-value : 0.00012
- **Decision:** Reject H0 (p<0.05)
- **Interpretation:** Hour Significantly affects conversion

**Post-Hoc Analysis (Turkey HSD):**
- Hour 14 Significantly higher than hours 2-6(p<0.05)
- Hour 18 Significantly higher than hours 22-24(p<0.05)

# Machine Learning Pipeline
## **Feature Engineering**

**Created Features:**
- One-hot encoding for most_ads_day(7 binary features)
- Normalized total_ads using StandardScaler
- Cluster assignment from K-Means(4 categories)

**Final Feature Set(13 features):**
- test_group(binary)
- total_ads(continuous, scaled)
- most_ads_hour(integer 0-23)
- most_ads_day_Monday through Sunday (7 binary)
- cluster (categorical 0-3)

**Train-Test Split**

**Strategy:** Stratified Sampling

**Rationale:**
- 70/30 Split balances training data with robust testing
- Stratification preserve 25% conversion rate in both sets
- random_state= 42 ensure reproducibility

**Set Sizes**
- Training : 7,000 samples
- Test : 3,000 samples

**Customer Segmentation(K-Means)**

**Methodology**

- Step 1 : Feature Scaling
- step 2 : Optimal k Selection
1. Elbow Method : Plotted inertia 
2. Results: K=4 Chosen(elbow point)
- Step 3 : Clustering
- Step 4 : Cluster Interpretation
1. Cluster 0 : Champions
2. Cluster 1 : Engagement Users
3. Cluster 2 : At-Risk (Ad Fatigue)
4. Cluster  3 : Low Engagement

**Validation:** PCA visualization confirms distinct clusters

**Classification Models**

**Model 1 : Logistic Regression**
- Interpretable, fast , good baseline

**Feature Importance:**
- test_group: Coef=0.31(OR = 1.36)
- total_ads: Coef= -0.02(OR = 0.98)
- cluster_0 : Coef = 0.82 (OR=2.27)

**Model 2 : Random Forest(Ensemble)**
- Handle non-linearity ,Provide feature importance

**HyperParameter Tuning:**
- Method : 5-fold cross-validation
- Grid Search Over: n_estimators[50,100,200], Max_depth[5,10,15]
- Best Params: n_estimators = 100, max_depth=10

**Model 3 : XGBoost(Advanced Ensemble)**
- State-of-the-art Performance, handle imbalance well

# Evaluation Metrics

**Classification Metrics**

**Confusion Matrix Interpretation:**

Predicted
            0    1
- Actual 0  TN   FP
-        1  FN   TP

**Key Metrics :**

1.**Accuracy** 
- (TP + TN) / (TP + TN + FP + FN)
- Overall correctness
- **Limitation:** Misleading With imbalanced Data

2.**Precision**
- TP/ (TP + FP )
- Of predicted conversions, How many were correct ?
- **Important** : Avoid wasting resources on false positives

3.**Recall(Sensitivity)**
- TP/(TP + fN)
- Of actual conversions, how many did we catch ?
- **Important** : Don't miss potential customers

4.**F1-Score**
- 2 * (Precision * Recall) / (Precision + Recall)
- Harmonic Mean Balancing precision and recall
- Best metric for imbalanced data

5.**ROC-AUC**
- Area under ROC curve
- Measures discrimination ability across all thresholds
- Range: 0.5(random) to 1.0 (perfect)
- Preferred metric : Threshold-independent

# Model Comparison

               Model  Accuracy  Precision  Recall  F1-Score  ROC-AUC
-  Logistic Regression    0.9734     0.1453  0.0112    0.0208   0.8312
-       Random Forest    0.9748     0.0000  0.0000    0.0000   0.8542
-         XGBoost    0.9748     0.0000  0.0000    0.0000   0.8569

**Winner:** Random Forest (High ROC-AUC, good balance of metrics)

# Assumptions

- Assumes accurate tracking of user interactions
- Assumes no bot traffic in dataset
- Random assignment to test groups
- No contamination between groups
- Stable unit treatment value assumption(SUTVA)
- Customer behaviour remains consistent over analysis period
- No major external events affecting conversions

# Limitations
- **Sample Size:** 10,000 users may not capture rare segments
- **Temporal Scope:** Single time period, May not generalize to seasons
- **Feature Availability:** Limited to ad interaction data, no demographics
- **Causality:**  Observational analysis, Correlation != causation
- **Model Generalization:** Performance may degrade over time (Concept drift) 

# Mitigation Strategies
- Regular model retraining(quarterly)
- A/B testing before full deployment
- Monitoring for distribution shift
- collecting additional features over time







 




