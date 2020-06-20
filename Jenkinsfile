#!/usr/bin/env groovy
@Library('share-library@master') _

"""
初始化对象
"""
def logs_ = new com.tct.log()
def utils_ = new com.tct.utils()

def test = new com.tct.example.Test(log, utils)
def cat = new com.tct.example.Cat("mimi")
def dog = new com.tct.example.Dog("dahuang", log, utils)

pipeline {
    agent {
        node {
            label "ws186"
            customWorkspace "/home/yafeng/jobs/${JOB_NAME}"
        }
    }

    environment {
        CC = 'clang'
    }

    stages {
        stage('init') {
            steps {
                echo 'This stage will be executed first.'
            }
        }

        stage('build') {
            // when {
            //     not { branch 'master' }
            // }

            failFast true
            parallel {
                stage('build A') {
//                    agent {
//                        label "ws186"
//                    }
                    steps {
                        echo "On build A"
                        echo "Hello, ${CC}, nice to meet you."
                    }
                }

                stage('build B') {
                    // agent {
                    //     label "10.129.46.20"
                    // }

                    steps {
                        echo "On build B"
                        echo "Hello, ${CC}, nice to meet you."

                        script {
                            println(currentBuild.displayName)
                            println(currentBuild)
                            println('---- currentBuild ----')

                            test.run()
                            cat.run()
                            dog.run()

                            log.v('测试log输出功能')
                            log.d('测试log输出功能')
                            log.i('测试log输出功能')
                            log.w('测试log输出功能')
//                            log.e('测试log输出功能')

                            utils.command("ls -al")

//                            email = "514779897@qq.com"
//                            utils.send_email("构建成功...1",  email)
//                            utils_.send_email("构建成功...2", email)

                            def browsers = ['chrome', 'firefox']
                            for (int i = 0; i < browsers.size(); ++i) {
                                echo "Testing the ${browsers[i]} browser"
                            }
                        }
                    }
                }
            }
        }
    }
}
