#!/usr/bin/env python3
##########################################################
# Script Name   : email-checker.py
# Description   : Check unseen email and show notification
# Date          : 24/07/2020
# Author        : H.R. Shadhin <dev@hrshadhin.me>
# License       : GPL-3.0
##########################################################

import os
import time
import subprocess

from dotenv import load_dotenv
import gmail

# discover .env and load variables
load_dotenv()

# set variables
hrs_mailbox = (os.getenv("HRS_MAIL_USER", ""), os.getenv("HRS_MAIL_PASS", ""))
cs_mailbox = (os.getenv("CS_MAIL_USER", ""), os.getenv("CS_MAIL_PASS", ""))
office_mailbox = (os.getenv("OFFICE_MAIL_USER", ""), os.getenv("OFFICE_MAIL_PASS", ""))

# mail boxes
mailboxes = {
    'HRS': hrs_mailbox,
    "CS": cs_mailbox,
    "OFFICE": office_mailbox
}


def show_notification(title: str, message: str) -> None:
    """
    Show notification via `notify-send` tool.
    This tool is default installed on GNU/Linux system.
    For other platform use different tools.

    :param title: str
    :param message: str
    :return: None
    """
    icon_path = os.path.dirname(os.path.abspath(__file__)) + "/icon-mail.png"
    subprocess.Popen(['notify-send', title, '-i', icon_path, message])


def get_unseen_emails(username: str, password: str) -> list:
    """
    Login to gmail and get unseen emails

    :param username: str
    :param password: str
    :return: list
    """

    g = gmail.login(username, password)
    unseen_mails = g.inbox().mail(unread=True)
    g.logout()

    return unseen_mails


def main():

    for account_name, access_info in mailboxes.items():
        user, password = access_info
        if len(user) and len(password):
            unseen_mails = get_unseen_emails(user, password)
            total_unseen = len(unseen_mails)
            if total_unseen:
                show_notification(account_name, f"{total_unseen} unseen email(s) have in your mailbox!")

            # sleep for 10 sec
            time.sleep(10)



if __name__ == '__main__':
    main()
