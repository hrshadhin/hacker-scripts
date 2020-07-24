#!/bin/bash

# activate venv
. venv/bin/activate

# run python script
echo "Checking mailboxes...."
python email-checker.py

# deactivate venv
deactivate

echo "Finished!"
