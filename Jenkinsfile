#!/usr/bin/env groovy
//@Library('jenkinslibrary@master') _

"""
初始化对象
"""

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

                        // sh 'sleep 5'
                        // sh 'touch branch_a'
                        // sh 'touch branch_xxx'
                    }
                }

                stage('build B') {
                    // agent {
                    //     label "10.129.46.20"
                    // }
                    steps {
                        echo "On build B"
                        echo "Hello, ${CC}, nice to meet you."

                        // sh 'sleep 5'
                        // sh 'touch branch_b'

//                        script {
//                            println(currentBuild.displayName)
//                            println(currentBuild)
//                            tools.cmd("test sh func ...")
//
//                            tt.init()
//
//                            cat.run()
//
//                            utils.print_env()
//
//                            log.v('测试log输出功能')
//                            log.d('测试log输出功能')
//                            log.i('测试log输出功能')
//                            log.w('测试log输出功能')
//                            log.e('测试log输出功能')
//
//                            d.init()
//                            d.setName("小黄")
//                            println(d.getName())
//                            d.run()
//                            println(d.getName())
//
//                            userEmail = "514779897@qq.com"
//                            tools.PrintMes("测试 Share lib 成功","green")
//                            // toemail.Email("代码质量阈错误！请及时修复！",userEmail)
//                            def browsers = ['chrome', 'firefox']
//                            for (int i = 0; i < browsers.size(); ++i) {
//                                echo "Testing the ${browsers[i]} browser"
//                            }
//                        }
                    }
                }
            }
        }
    }
}
