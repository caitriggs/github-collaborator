import logging

def configure_logging(level):
    # create logger
    logger = logging.getLogger('reco-cs')
    logger.setLevel(getattr(logging,level))

    # create console handler and set level to debug
    ch = logging.StreamHandler()
    ch.setLevel(getattr(logging,level))

    # create formatter
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    # add formatter to ch
    ch.setFormatter(formatter)

    # add ch to logger
    logger.addHandler(ch)
