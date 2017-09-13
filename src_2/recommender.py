import logging
import numpy as np
import pandas as pd
import pyspark
from pyspark.sql import SparkSession
from pyspark.ml.recommendation import ALS

spark = SparkSession.builder.getOrCreate()

class MovieRecommender():
    """Template class for a Movie Recommender system."""

    def __init__(self):
        """
        Constructs a MovieRecommender

        """
        self.logger = logging.getLogger('reco-cs')


    def fit(self, ratings):
        """
        Trains the recommender on a given set of ratings.

        Parameters
        ----------
        ratings : pandas dataframe, shape = (n_ratings, 4)
                  with columns 'user', 'movie', 'rating', 'timestamp'

        Returns
        -------
        self : object
            Returns self.
        """
        #Create Spark df
        spark_ratings = spark.createDataFrame(ratings)

        self.logger.debug("starting fit")
        als_model = ALS(
            itemCol='movie',
            userCol='user',
            ratingCol='rating',
            nonnegative=True,
            regParam=0.1,
            rank=10
            )
        self.recommender = als_model.fit(spark_ratings)
        self.logger.debug("finishing fit")
        return(self)

    def transform(self, requests):
        """
        Predicts the ratings for a given set of requests.

        Parameters
        ----------
        requests : pandas dataframe, shape = (n_ratings, 2)
                  with columns 'user', 'movie'

        Returns
        -------
        dataframe : a pandas dataframe with columns 'user', 'movie', 'rating'
                    column 'rating' containing the predicted rating
        """
        self.logger.debug("starting predict")

        #Create Spark df
        spark_requests = spark.createDataFrame(requests)
        self.logger.debug("request count: {}".format(requests.shape[0]))

        #First wave of predictions is simply randomly generating ratings
        #requests['rating'] = np.random.choice(range(1, 5), requests.shape[0])

        #Second wave of predictions actually made from our model
        predictions_df = self.recommender.transform(spark_requests)
        #Convert spark df to a pandas df and load Brians predictions so we can join
        predictions_df = predictions_df.toPandas()
        brian_df = pd.read_csv('submissions/brians_meanmovierating_userbias.csv')
        #Impute missing predictions from Brian's naive model
        ALS_join = pd.merge(predictions_df, brian_df, how='left', on=["user","movie"])
        ALS_join['prediction'].fillna(value=ALS_join.rating, inplace=True)
        #Drop Brian's rating column
        ALS_join = ALS_join.drop('rating', axis=1)
        #Rename prediction column to rating
        final_df = ALS_join.rename(columns={'prediction':'rating'})

        self.logger.debug("finishing predict")
        return final_df

if __name__ == "__main__":
    logger = logging.getLogger('reco-cs')
    logger.critical('you should use run.py instead')
