#!/usr/bin/python
# -*- coding:UTF-8 -*-

import sys
import smtplib
from email.mime.text import MIMEText
from email.header import Header


def send_mail(subject, content):
    mail_host = 'mailsz.tct.tcl.com'
    mail_user = 'Integration.tablet'
    mail_pass = 'mobile#1'
    #    receivers=getConfig('mail','mailto').split(',')
    receivers = email_list.split(',')

    message = MIMEText(content, 'plain', 'utf-8')
    sender = 'Integration.tablet@tcl.com'
    message['From'] = Header("Integration.tablet", 'utf-8')
    message['Subject'] = Header(subject, 'utf-8')

    try:
        smtpObj = smtplib.SMTP()
        smtpObj.connect(mail_host, 25)  # 25 为 SMTP 端口号
        # smtpObj.login('123', '123')
        smtpObj.login(mail_user, mail_pass)
        smtpObj.sendmail(sender, receivers, message.as_string())
        print (">>> 邮件已发送成功.")
    except (smtplib.SMTPException):
        print ("Error: >>> 邮件已发送失败.")


# noinspection PyInterpreter
if __name__ == '__main__':

    rom_p = "/local/telweb/"

    zip_project = sys.argv[1]
    zip_type = sys.argv[2]
    zip_version = sys.argv[3]
    email_list = sys.argv[4]
    isdelivery = sys.argv[5]

    print "the zip_project is %s" % zip_project
    print "the zip_type is %s" % zip_type
    print "the zip_version is %s" % zip_version
    print "the email_list is %s" % email_list
    print "the isdelivery is %s" % isdelivery

    if isdelivery == 'true':
        content = zip_project + '/' + zip_version + '/' + zip_type \
                  + ' 版本已压缩成功.' + "\n" + 'teleweb路径:'  \
                  + rom_p + '/' + zip_project + '/' + zip_type + '/' + zip_version

        subject = '%s-%s 版本压缩' % (zip_project, zip_version)
    else:
        content = zip_project + '/' + zip_version + '/' + zip_type + ' 压缩版本失败,请告知集成组同事处理,谢谢!'
        subject = '%s-%s 压缩版本' % (zip_project, zip_version)

    send_mail(subject, content)
