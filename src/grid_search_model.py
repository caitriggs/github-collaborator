import pandas as pd
import numpy as np

import pyspark
from pyspark.sql import SparkSession
from pyspark.ml.recommendation import ALS, ALSModel
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder

# Setup a SparkSession
spark = SparkSession.builder.getOrCreate()


def load_data_toSpark():
    traindata = pd.read_csv('../data/new_subset_data/final_train_data.csv')
    testdata = pd.read_csv('../data/new_subset_data/final_test_data.csv')

    sp_train = spark.createDataFrame(traindata)
    sp_test = spark.createDataFrame(testdata)

    #Change column names to something Spark has hardcoded into their GridSearch feature for dataframes
    oldColumns = sp_train.schema.names
    newColumns = ["user", "item", "rating"]
    sp_train = reduce(lambda sp_train, idx: sp_train.withColumnRenamed(
        oldColumns[idx], newColumns[idx]), xrange(len(oldColumns)), sp_train)

    #Change column names to something Spark has hardcoded into their GridSearch feature for dataframes
    oldColumns = sp_test.schema.names
    newColumns = ["user", "item", "rating"]

    sp_test = reduce(lambda sp_test, idx: sp_test.withColumnRenamed(
        oldColumns[idx], newColumns[idx]), xrange(len(oldColumns)), sp_test)

    return sp_train, sp_test

def bestModel_from_GridSearch(sp_train):
    als = ALS(nonnegative=True, coldStartStrategy=True)

    paramGrid = ParamGridBuilder() \
        .addGrid(als.maxIter, [15, 40]) \
        .addGrid(als.regParam, [1, 0.1, 0.01, 5]) \
        .addGrid(als.rank, [10,15,20,25,30,35,40]) \
        .build()

    crossval = CrossValidator(estimator=als,
                              estimatorParamMaps=paramGrid,
                              evaluator=RegressionEvaluator(
                                  metricName="rmse",
                                  labelCol="rating"),
                              numFolds=7)
    alsModel = crossval.fit(sp_train)
    alsModel.bestModel.save('/home/ubuntu/PROJECT/github-collaborator/data/models/CVmodel')
    return alsModel.bestModel

def evaluate_models(trained_models, testdf, metric='rmse'):
    '''
    INPUT: list of trained models, and spark dataframe of training data
    OUTPUT: list of rmses, and list of ranks associated with models

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

if __name__ == '__main__':
    print "Creating Spark dataframes"
    sp_train, sp_test = load_data_toSpark()
    print "Grid Searching to find best model...t"
    best_model = bestModel_from_GridSearch(sp_train)
    print "Calculating RMSE for test data"
    rmse, rank = evaluate_models([best_model], sp_test)
    print "Best model tests at RMSE: {} at rank {}".format(rmse[0], rank[0])
