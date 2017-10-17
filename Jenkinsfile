#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
  }

  stages {
    stage('Test') {
      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml'
      }
    }

    stage('Publish to RubyGems') {
      agent { label 'releaser-v2' }
      when {
        branch 'master'
      }

      steps {
        checkout scm
        sh './publish-rubygem.sh'
        deleteDir()
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
