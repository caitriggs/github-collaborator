import sys
import pandas as pd
from submit import compute_score
import pyspark.sql
from pyspark.ml.tuning import CrossValidator
import numpy as np


def evaluate_recommender(model, train, test):
    '''
    Simple function for evaluation. Takes a model, train, and test set.
    Fits to train, predicts on test.
    ASSUMES OUTPUT OF model.transform(test) IS A DATAFRAME WITH A 'prediction' COLUMN.
    '''

    fit_model = model.fit(train)
    predicted = fit_model.transform(test)
    test_pd = test.toPandas()
    test_pd['actuallystarred'] = test_pd['starred']
    test_pd.drop('starred', axis=1, inplace=True)
    predicted_pd = predicted.toPandas()
    #if 'prediction' in predicted_pd.columns.values:
    #    predicted_pd['prediction'] = predicted_pd['prediction']
    return compute_score(predicted_pd[['user_id', 'repo_id', 'prediction']],
                         test_pd[['user_id', 'repo_id', 'actuallystarred']])

# def cv_score(model,train):#     cv = CrossValidator(estimator=model, evaluator=None)


def holdout_score(model, data):
    '''
    Input: model instance with .fit and .transfrom
           data as spark dataframe
    '''
    train, test = data.randomSplit([0.8, 0.2])
    score = evaluate_recommender(model, train, test)
    return score


def bad_k_scores(model, data, k):
    '''
    Input: model instance with .fit and .transfrom
           data as spark dataframe
           k: int number of times to split & score
    Returns: dict {'mean_score': float
                   'scores': list}
    '''
    scores = []
    for i in xrange(k):
        scores.append(holdout_score(model, data))
    return {'mean_score': np.mean(scores), "scores":scores}
