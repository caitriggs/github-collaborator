import sys
import logging
import argparse
import pandas as pd

def compute_score(predictions, actual):
    """Look at 5% of most highly predicted movies for each user.
    Return the average actual rating of those movies.
    """
    df = pd.merge(predictions, actual, on=['user','movie']).fillna(1.0)
    #df = pd.concat([predictions.fillna(1.0), actual.actualrating], axis=1)

    # for each user
    g = df.groupby('user')

    # detect the top_5 movies as predicted by your algorithm
    top_5 = g.rating.transform(
        lambda x: x >= x.quantile(.95)
    )

    # return the mean of the actual score on those
    return df.actualrating[top_5==1].mean()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--silent', action='store_true', help="deactivate debug output")
    parser.add_argument('--testing', help="testing set")
    parser.add_argument("predfile", nargs=1, help="prediction file to submit")

    args = parser.parse_args()

    if args.silent:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s',
                            datefmt='%m/%d/%Y %I:%M:%S %p',
                            level=logging.INFO)
    else:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s',
                            datefmt='%m/%d/%Y %I:%M:%S %p',
                            level=logging.DEBUG)
    logger = logging.getLogger('reco-cs')

    path_testing_ = args.testing if args.testing else "data/testing.csv"
    logger.debug("using groundtruth from {}".format(path_testing_))

    logger.debug("using predictions from {}".format(args.predfile[0]))
    prediction_data = pd.read_csv(args.predfile[0])

    if prediction_data.shape[0] != 200209:
        error_msg_ = " ".join(["Your matrix of predictions is the wrong size.",
        "It should provide ratings for {} entries (yours={}).".format(200209,prediction_data.shape[0])])
        logger.critical(error_msg_)
        #sys.exit(-1)

    actual_data = pd.read_csv(path_testing_)

    score = compute_score(prediction_data, actual_data)
    print(score)
    logger.debug("score={}".format(score))
