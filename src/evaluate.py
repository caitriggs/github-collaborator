import pandas as pd
import numpy as np
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.mllib.recommendation import ALS


def evaluate_models(trained_models, testdf, metric='rmse'):
    '''
    INPUT |
    trained_model: list of trained models
    testdf: Spark dataframe of ratings data

    OUTPUT |
    rmses: list of RMSE scores
    ranks: list of ranks associated with each model

    Example |
    trained_models = [recommender1, recommender2]
    testdf = spark.createDataFrame(test_pandas_df)

    rmses, ranks =  evaluate_models(trained_models, testdf)
    '''
    ranks = []
    rmses = []
    for model in trained_models:
        predictions = model.transform(testdf)
        pred_df = predictions.toPandas()
        rawPredictions = spark.createDataFrame(pred_df.dropna(axis=0))

        predictions = rawPredictions\
        .withColumn("rating", rawPredictions.rating.cast("double"))\
        .withColumn("prediction", rawPredictions.prediction.cast("double"))

        evaluator =\
        RegressionEvaluator(metricName=metric, labelCol="rating", predictionCol="prediction")
        rmse = evaluator.evaluate(predictions)

        ranks.append(model.rank)
        rmses.append(rmse)
    return rmses, ranks
