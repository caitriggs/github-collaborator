import pandas as pd
from sqlalchemy import create_engine
import numpy as np
import matplotlib.pyplot as plt

from pyspark import SparkContext
import pyspark.sql.functions

from pyspark.mllib.recommendation import ALS, MatrixFactorizationModel, Rating
from pyspark.mllib.evaluation import RankingMetrics


def read_data(ratings_file_path):
    '''CSV files must contain header: user_id,repo_id,rating'''
    # Read in the ratings data for training set
    ratings = sc.textFile(ratings_file_path)
    # Filter out first column of the header
    ratings_data = ratings.filter(lambda l: not l.startswith('user_id'))
    return ratings_data

def parseLine(line, sep=','):
    '''Parse RDD into a Ratings() object for ALS model: user,item,rating'''
    fields = line.split(sep)
    return Rating(user=int(fields[0]), product=int(fields[1]), rating=float(fields[2]))

def create_model(RDD_ratings_data):
    '''Create the final ALS model on the entire set of ratings (after training/testing work)'''
    model = ALS.trainImplicit(RDD_ratings_data,
                              rank=50,
                              iterations=20,
                              lambda_=10.0,
                              alpha=20.0)
    return model

def get_reco_repo_ids(model, userID, k=25):
    '''
    model: ALS recommender model
    userID: the id of the user for which you want recommendations
    k: number of recommendations
    '''
    predictions = model.recommendProducts(userID, k)
    return [predictions[i].product for i in range(len(predictions))]

def get_recomm_repo_urls(lookupdf, repo_ids):
    '''
    lookupdf: pandas df that contains the column repo_id
    repo_ids: a list of recommended repo_ids provided by get_reco_repo_ids
    '''
    return lookupdf[lookupdf['repo_id'].isin(repo_ids)]


if __name__ == '__main__':
    #Create Spark context for RDD based ALs recommender
    sc = SparkContext.getOrCreate()
    #Train final model on entire user-repo ratings db
    ratings_data_path = "data/new_subset_data/entire_commits.csv"
    #Create RDDs
    ratings_RDD = read_data(train_data_path, test_data_path)
    #Create Ratings objects for ALS model: user, item, rating
    entire_set = ratings_RDD.map(lambda r: parseLine(r))
    #Create model
    model = create_model(entire_set)
    #Create user-repo lookup dataframe
    users_repos = pd.read_csv('data/user_repo_lookup.csv', sep='\t')
    #Get 25 repo_id recommendations for user madrury
    repo_ids = get_recomm_repo_ids(model, 1795649, 25)
    #Get the info for recommended repos
    madrury_recs = get_recomm_repo_urls(users_repos, repo_ids)
    print madrury_recs
