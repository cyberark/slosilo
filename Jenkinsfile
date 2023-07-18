#!/usr/bin/env groovy
@Library("product-pipelines-shared-library") _

pipeline {
  agent { label 'conjur-enterprise-common-agent' }

  triggers {
    cron(getDailyCronString())
  }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
  }

  stages {
    stage('Get InfraPool Agent') {
      steps {
        script {
          INFRAPOOL_EXECUTORV2_AGENT_0 = getInfraPoolAgent.connected(type: "ExecutorV2", quantity: 1, duration: 1)[0]
          INFRAPOOL_EXECUTORV2_RHEL_EE_AGENT_0 = getInfraPoolAgent.connected(type: "ExecutorV2RHELEE", quantity: 1, duration: 1)[0]
        }
      }
    }

    stage('Test') {
      parallel {
        stage('Run tests on EE') {
          steps {
            script {
              INFRAPOOL_EXECUTORV2_RHEL_EE_AGENT_0.agentSh './test.sh'
            }
          }
          post { always {
            script {
              INFRAPOOL_EXECUTORV2_RHEL_EE_AGENT_0.agentStash name: 'eeTestResults', includes: 'spec/reports/*.xml', allowEmpty:true
            }
          }}
        }

        stage('Run tests') {
          steps {
            script {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh './test.sh'
              INFRAPOOL_EXECUTORV2_AGENT_0.agentStash name: 'TestResults', includes: 'spec/coverage/*.xml', allowEmpty:true
            }
          }
        }
      }
    }

    stage('Publish to RubyGems') {
      when {
        allOf {
          branch 'master'
          expression {
            boolean publish = false

            try {
              timeout(time: 5, unit: 'MINUTES') {
                input(message: 'Publish to RubyGems?')
                publish = true
              }
            } catch (final ignore) {
              publish = false
            }

            return publish
          }
        }
      }

      steps {
        script {
          INFRAPOOL_EXECUTORV2_AGENT_0.agentDir('publish-slosilo') {
            INFRAPOOL_EXECUTORV2_AGENT_0.agentSh './publish-rubygem.sh'
            checkout scm
          }
          INFRAPOOL_EXECUTORV2_AGENT_0.agentDeleteDir('publish-slosilo')
        }
      }
    }
  }

  post {
    always {
      dir('ee-results'){
        unstash 'eeTestResults'
      }
      unstash 'TestResults'
      junit 'spec/reports/*.xml, ee-results/spec/reports/*.xml'
      cobertura coberturaReportFile: 'spec/coverage/coverage.xml'
      sh 'cp spec/coverage/coverage.xml cobertura.xml'
      codacy action: 'reportCoverage', filePath: "spec/coverage/coverage.xml"
      releaseInfraPoolAgent(".infrapool/release_agents")
    }
  }
}
