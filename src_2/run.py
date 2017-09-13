import sys
import logging
import argparse
from recommender import MovieRecommender     # the class you have to develop
import pandas as pd
from log import configure_logging


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", help="path to training ratings file (to fit)")
    parser.add_argument("--requests", help="path to the input requests (to predict)")
    parser.add_argument('--silent', action='store_true', help="deactivate debug output")
    parser.add_argument("outputfile", nargs=1, help="output file (where predictions are stored)")

    args = parser.parse_args()

    if args.silent:
        configure_logging('INFO')
    else:
        configure_logging('DEBUG')
    logger = logging.getLogger('reco-cs')

    path_train_ = args.train if args.train else "data/training.csv"
    logger.debug("using training ratings from {}".format(path_train_))

    path_requests_ = args.requests if args.requests else "data/requests.csv"
    logger.debug("using requests from {}".format(path_requests_))

    logger.debug("using output as {}".format(args.outputfile[0]))

    # Reading REQUEST SET from input file into pandas
    request_data = pd.read_csv(path_requests_)

    # Reading TRAIN SET from input file into pandas
    train_data = pd.read_csv(path_train_)

    # Creating an instance of your recommender with the right parameters
    reco_instance = MovieRecommender()

    # fits on training data, returns a MovieRecommender object
    model = reco_instance.fit(train_data)

    # apply predict on request_data, returns a dataframe
    result_data = model.transform(request_data)

    # test if the format of results is ok
    if (result_data.shape[0] != request_data.shape[0]) or (result_data.shape[1] != 3):
        logger.critical(
                        "wrong shape of prediction (request={} expected={})"\
                        .format(result_data.shape,(request_data.shape[0],3))
                        )
        sys.exit(-1)

    result_data.to_csv(args.outputfile[0], index=False)
