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
    class Lenaw < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        
        # GET LENA FILE PATH
        lenaBinPath = "/tmp/buildpackdownloads/"
        tmpDirPathArr = Dir.entries(lenaBinPath)
        lenaBinPath = lenaBinPath+tmpDirPathArr[2]+"/binary"

        # LENA Install file (이미지 생성시 사용)
        lenaInstallScriptPath = lenaBinPath + "/installScript/"
        lenaInstallScriptPathArr = Dir.entries(lenaInstallScriptPath)
        lenaInstallScriptPath = lenaInstallScriptPath + lenaInstallScriptPathArr[2]

        # LENA entrypoint file (컨테이너 기동시 사용)
        lenaEntryScriptPath = lenaBinPath + "/entryScript/"
        lenaEntryScriptPathArr = Dir.entries(lenaEntryScriptPath)
        lenaEntryScriptPath = lenaEntryScriptPath + lenaEntryScriptPathArr[2]

        # move install shell / entry shell
        move_to(lenaInstallScriptPath,@droplet.sandbox)
        installShPath = "#{@droplet.sandbox}/"+ lenaInstallScriptPathArr[2]
        chmod(installShPath,755)
        move_to(lenaEntryScriptPath,@droplet.sandbox)
        entryShPath = "#{@droplet.sandbox}/"+ lenaEntryScriptPathArr[2]
        chmod(entryShPath,755)

        # Download LENA WEB install file and extract
        download(@version, @uri) { |file| expand file }
        # Call Lena Install shell
        run_sh installShPath

        # move proxy conf
        userProxyPath="/tmp/app/proxy.conf"
        lenaProxyPath = "/tmp/app/.java-buildpack/lenaw/servers/webServer/conf/extra/proxy/proxy_vhost_default.conf"
        move_to2(userProxyPath,lenaProxyPath)
        
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        @droplet.environment_variables.add_environment_variable 'JAVA_OPTS', '$JAVA_OPTS'
        @droplet.java_opts.add_system_property 'http.port', '$PORT'

        [
          @droplet.environment_variables.as_env_vars,
          @droplet.java_home.as_env_var,
          'exec',
          "$PWD/#{(@droplet.sandbox + 'entrypoint.sh').relative_path_from(@droplet.root)}",
          'run'
        ].flatten.compact.join(' ')

      end

      protected

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def supports?
        # web_inf? && !JavaBuildpack::Util::JavaMainUtils.main_class(@application)
        true
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
          
          shell "tar xzf #{file.path} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"

          @droplet.copy_resources
        
        end
      end

      def expandByPath(filePath)
        with_timing "Expanding By Path #{@component_name} to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          
          shell "tar xzf #{filePath} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"

          @droplet.copy_resources

          print "\n#{'----->'.green.bold} Expanding By Path LENA  \n"          
        end
      end

      def link_to(source, destination)
        FileUtils.mkdir_p destination
        source.each { |path| (destination + path.basename).make_symlink(path.relative_path_from(destination)) }
      end

      def move_to(source, destination)
        print "#{'----->'.green.bold} move file from  #{source} to #{destination}   \n"
        FileUtils.mkdir_p destination
        shell "mv #{source} #{destination}" 
      end

      def move_to2(source, destination)
        print "#{'----->'.green.bold} move file from  #{source} to #{destination}  \n"
        shell "mv #{source} #{destination}" 
      end

      def run_sh(shPath)
        print "#{'----->'.green.bold} run shell #{shPath}  \n"
        shell "sh -x #{shPath}"       
      end
      
      def chmod(shPath, authVar)
            print "#{'----->'.green.bold} chmod  #{authVar} #{shPath}  \n"
            shell "chmod #{authVar} #{shPath}"   
      end

    end

  end
end