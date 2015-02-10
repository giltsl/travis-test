module DPL
        class Provider
                class TestFairy < Provider

                        require "net/http"
                        require "uri"
                        require 'net/http/post/multipart'
                        require 'json'
                        require 'open-uri'
                        require 'tempfile'


                        @@tag = "-Testfairy-"
                        # @@SERVER = "http://api.testfairy.com"
                        @@SERVER = "http://giltsl.gs.dev.testfairy.net"
                        @@UPLOAD_URL_PATH = "/api/upload";
                        @@UPLOAD_SIGNED_URL_PATH = "/api/upload-signed";

                        @@zipPath = "/usr/bin/zip"
                        @@jarsignerPath = "/usr/bin/jarsigner"
                        @@zipAlignPath = "/Users/gilt/apps/testfairy_git/server/deployment/bin/darwin/platform-tools/zipalign"

                        def check_auth

                                puts "check_auth #{@@tag}"
                                puts "api-key = #{option(:api_key)} proguard-file = #{option(:proguard_file)}"
                                puts "keystore-file = #{option(:keystore_file)} storepass = #{option(:storepass)} alias = #{option(:alias)}"



                        end

                        def deploy
                                super
                                puts "deploy #{@@tag}"
                        end

                        def needs_key?
                                false
                        end

                        def push_app

                                puts "push_app #{@@tag}"
                                response = uploadApp
                                puts response['instrumented_url']
                                instrumentedFile = download_from_url response['instrumented_url']
                                if "#{option(:platform)}" == "android"
                                        signedApk = signingApk instrumentedFile
                                        upload_signed_apk signedApk
                                end
                                puts "Upload access!, check your build on #{response['build_url']}"
                        end

                        def signingApk(instrumentedFile)

                                signed = Tempfile.new(['instrumented-signed', '.apk'])

                                context.shell "ls #{instrumentedFile}"
                                context.shell "#{@@zipPath} -qd #{instrumentedFile} META-INF/*"
                                context.shell "#{@@jarsignerPath} -keystore #{option(:keystore_file)} -storepass #{option(:storepass)} -digestalg SHA1 -sigalg MD5withRSA #{instrumentedFile} #{option(:alias)}"
                                context.shell "#{@@jarsignerPath} -verify  #{instrumentedFile}"

                                context.shell "#{@@zipAlignPath} -f 4 #{instrumentedFile} #{signed.path}"
                                puts "signing Apk finished: #{signed.path()}  (file size:#{File.size(signed.path())} )"
                                signed.path()
                        end

                        def download_from_url(url)
                                puts "downloading  from #{url} "
                                uri = URI.parse(url)
                                instrumentedFile = Net::HTTP.start(uri.host, uri.port) do |http|
                                        resp = http.get(uri.path)
                                        file = Tempfile.new(['instrumented', '.apk'])
                                        file.write(resp.body)
                                        file.flush
                                        file
                                end
                                puts "Done #{instrumentedFile.path()}  (file size:#{File.size(instrumentedFile.path())} )"
                                instrumentedFile.path()
                        end

                        def uploadApp

                                uploadUrl = @@SERVER + @@UPLOAD_URL_PATH
                                puts uploadUrl
                                uri = URI.parse(uploadUrl)
                                request = get_request uri, option(:apk)
                                res = Net::HTTP.start(uri.host, uri.port) do |http|
                                        http.request(request)
                                end

                                puts res.code       # => '200'
                                puts res.message    # => 'OK'
                                puts res.class.name # => 'HTTPOK'
                                puts res.body
                                JSON.parse(res.body)
                        end

                        def upload_signed_apk (apkPath)

                                uploadSignedUrl = @@SERVER + @@UPLOAD_SIGNED_URL_PATH
                                puts uploadSignedUrl
                                uri = URI.parse(uploadSignedUrl)
                                request = get_request uri, apkPath
                                res = Net::HTTP.start(uri.host, uri.port) do |http|
                                        http.request(request)
                                end

                                puts res.code       # => '200'
                                puts res.message    # => 'OK'
                                puts res.class.name # => 'HTTPOK'
                                puts res.body
                                JSON.parse(res.body)
                        end

                        def get_request(uri, apkPath)

                                req = Net::HTTP::Post::Multipart.new uri.path,
                                     "api_key" => "#{option(:api_key)}",
                                     "apk_file" => UploadIO.new(File.new("#{apkPath}"), "", "test.apk")
                        end
                end
        end
end

# api-key=123456789 --proguard-file-name="proguard file name"--keystore-file="keystore file" --storepass="storepass string" --alias="alias string"

# ---initialize ---- provider
# ---user_agent ---- provider
# ---option ---- provider
# ---initialize ---- provider
# ---user_agent ---- provider
# ---deploy ---- provider
# ---setup_git_credentials ---- provider
# Preparing deploy
# check_auth -Testfairy-
# ---check_app ---- provider
# ---cleanup ---- provider
# Saved working directory and index state WIP on testfairy: f8fa256 Merge branch 'master' of github.com:travis-ci/dpl
# HEAD is now at f8fa256 Merge branch 'master' of github.com:travis-ci/dpl
# Deploying application
# ---uncleanup ---- provider



