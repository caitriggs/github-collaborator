import py2neo as p2n
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import linear_kernel
from sklearn.feature_extraction.text import TfidfVectorizer


def return_repo_ids_for_user(username):
    query = '''
    // Return a user and its owned repos
    MATCH (:User {login: {username}})-[:OWNS]->(b)
    RETURN b;
    '''
    repos_records = graph.data(query, username=username)
    return [record['repo']['repoID'] for record in repos_records]


def get_repo_indices(readme_df, username):
    repoIDs = return_repo_ids_for_user(username)
    return readme_df.loc[repoIDs]


def check_readme_exists():
    pass

def create_tifidf_mat(df_column):
    tfidf = TfidfVectorizer(max_df=0.75)
    return tfidf.fit_transform(df_column)

def find_similar(tfidf_matrix, index, top_n = 5):
    cosine_similarities = linear_kernel(tfidf_matrix[index:index+1], tfidf_matrix).flatten()
    related_docs_indices = [i for i in cosine_similarities.argsort()[::-1] if i != index]
    return [(index, cosine_similarities[index]) for index in related_docs_indices][0:top_n]


if __name__ == '__main__':
    df = pd.read_pickle('../data/readme_df.pkl')
    graph = p2n.Graph("http://localhost:7474/db/data/", password="0")
    print get_repo_indices(df, 'candlepin')
