# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013-2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/util/java_main_utils'


module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for JEUS applications.
    class Lena < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        # download_tar
        # copy_application
        lenaBinPath = "/tmp/buildpackdownloads"
        tmpDirPathArray = Dir.entries(lenaBinPath)
        lenaBinPath = "/tmp/buildpackdownloads/"+tmpDirPathArray[2]+"/binary"
        #print "lenaBinPath : #{lenaBinPath}"
        lenaBinPathArray = Dir.entries(lenaBinPath)
        #print "lenaBinPathArray in lenaBinPath are #{lenaBinPathArray}"
        #lenaBinPath="/tmp/buildpackdownloads/"+tmpDirPathArray[2]+"/binary/"+lenaBinPathArray[2]
        lenaBinPath="/tmp/buildpackdownloads/"+tmpDirPathArray[2]+"/binary/"
        print "lenaBinPath : #{lenaBinPath}"
        expandByPath lenaBinPath
        #download(@version, @uri) { |file| expand file }
        link_to(@application.root.children, root)
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release

        @droplet.environment_variables.add_environment_variable 'JAVA_OPTS', '$JAVA_OPTS'
        @droplet.java_opts.add_system_property 'http.port', '$PORT'

        [
          @droplet.environment_variables.as_env_vars,
          @droplet.java_home.as_env_var,
          'exec',
          "$PWD/#{(@droplet.sandbox + 'back/start.sh').relative_path_from(@droplet.root)}",
          'run'
        ].flatten.compact.join(' ')

      end

      protected

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def supports?
        web_inf? && !JavaBuildpack::Util::JavaMainUtils.main_class(@application)
      end

      private

      def copy_application
        #link_to(@application.root.children, root)
        FileUtils.mkdir_p root
        @application.root.children.each { |child| FileUtils.cp_r child, root }
      end

      def create_dodeploy #debug jboss
        FileUtils.touch(webapps + 'ROOT.war.dodeploy')
      end

      def root
        @droplet.sandbox + 'webhome/autodeploy/test'
      end

      def web_inf?
        (@application.root + 'WEB-INF').exist?
      end

      def expand(file)
        with_timing "Expanding #{@component_name} to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          FileUtils.mkdir_p @droplet.sandbox+'pathcheck'
          shell "tar xzf #{file.path} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"

          @droplet.copy_resources

          print "------------------------ Expanding LENA --------------------------"

          #configure_linking
          #configure_jasper
        end
      end

      def expandByPath(filePath)
        with_timing "Expanding By Path #{@component_name} to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          FileUtils.mkdir_p @droplet.sandbox+'pathcheck'
          #shell "tar xzf #{filePath} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"
          installFilePath1=filePath+"lena-was-1.3.0.tar.gz"
          installFilePath2=filePath+"lena-was-1.3.1.tar.gz"
          installFilePath3=filePath+"install-lena-internal.sh"
          shell "tar xzf #{installFilePath1} -C #{@droplet.sandbox}/back --strip 1 --exclude webapps 2>&1"
          shell "tar xzf #{installFilePath2} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"
          shell "mv #{installFilePath3} #{@droplet.sandbox}" 
          

          @droplet.copy_resources

          print "------------------------ Expanding By Path LENA --------------------------"

          #configure_linking
          #configure_jasper
        end
      end

      def link_to(source, destination)
        FileUtils.mkdir_p destination
        source.each { |path| (destination + path.basename).make_symlink(path.relative_path_from(destination)) }
      end

    end

  end
end