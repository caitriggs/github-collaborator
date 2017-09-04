import urllib2
import os
import csv
import logging
from time import gmtime, strftime
import shutil
from shutil import copyfile
import os, glob, time, operator
from random import randint
from time import sleep

# The CSV file containing all the data
readmes_csv_file_name = "result_" + strftime("%m-%d-%Y-%H%M%S", gmtime()) + ".csv"
readmes_folder = "readme-data"

os.system('touch {}'.format(readmes_csv_file_name))

def create_empty_file(path):
  with open(path, 'a'):
    os.utime(path, None)

def create_folder(folder):
  # Create the folder if it doesn't exist
  if not os.path.exists(folder):
      os.makedirs(folder)

def get_log_file_name():
  file_name = "result-" + strftime("%Y-%m-%d_%H.%M.%S", gmtime()) + ".log"
  return os.path.join(log_folder_path, file_name)

def get_logger(log_file_path):
  # Helps us log the result of the script
  logger = logging.getLogger(__name__)
  logger.setLevel(logging.INFO)

  handler = logging.FileHandler(log_file_path)
  handler.setLevel(logging.INFO)

  # create a logging format
  formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
  handler.setFormatter(formatter)

  # add the handlers to the logger
  logger.addHandler(handler)

  return logger

def get_readme_url(user_name, repo_name):
  url = "https://raw.githubusercontent.com/" + user_name + "/" + repo_name + "/master/README.md"

  return url

request_number = 1

# See: https://stackoverflow.com/questions/1812115/how-to-safely-write-to-a-file
def safe_write_csv(csv_path, row_content):
    # Create a temporary file
    tmp_path = csv_path + '.tmp'
    create_empty_file(tmp_path)

    try:
        file = open(csv_path, 'r')
    except IOError:
        file = open(csv_path, 'w')

    # Copy existing csv data into the temporary file
    copyfile(csv_path, tmp_path)

    # Add new CSV data
    csvWriter = csv.writer(open(tmp_path, 'ab'))
    csvWriter.writerow(row_content)

    # Rename the original file
    orig_file_tmp_name = csv_path + '.toBeDeleted'
    os.rename(csv_path, orig_file_tmp_name)

    # Rename the temporary file to the original file
    os.rename(tmp_path, csv_path)

    # Delete the original file
    os.remove(orig_file_tmp_name)
    message = "SUCCESS for user " + row_content[0] + " with repo " + row_content[1]

    logger.info(message)
    print "Request #" + str(request_number) + ": " + message

def get_readme_file(user_name, repo_name):
  global request_number

  sleep(randint(0,2))

  # local_file = os.path.join(readmes_folder, "README.md")
  remote_url = get_readme_url(user_name, repo_name)
  logger.info("Getting " + remote_url)

  try:
    # Get the content of the README.md
    response = urllib2.urlopen(remote_url)
    content = response.read()
    safe_write_csv(readmes_csv_path, [user_name, repo_name, content])

  except:
    safe_write_csv(readmes_csv_path, [user_name, repo_name, "NULL"])
    message = "Could not get README.md from " + remote_url
    logger.error(message)
    print "ERROR: " + message

  request_number+= 1

# Define file paths and set up necessary files / folders
log_folder_path = os.path.join(readmes_folder, "log/")
log_file_path = get_log_file_name()
readmes_csv_path = os.path.join(readmes_folder, readmes_csv_file_name)

create_folder(readmes_folder)
create_folder(log_folder_path)
create_empty_file(log_file_path)

logger = get_logger(get_log_file_name())

#get_readme_file("codyromano", "fitbank-android")

if __name__ == '__main__':
    with open('../data/users_projects.csv', 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in reader:
            get_readme_file(row[0], row[1])
