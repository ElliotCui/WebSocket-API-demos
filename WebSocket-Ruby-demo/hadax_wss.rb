# All you need to build is websocket client,
# which is different from ActionCable building self server and client,
# You NEED to install `faye-websocket` gem first
# gem "faye-websocket"

require 'faye/websocket'
require 'eventmachine'
require 'json'
require "zlib"

module HadaxWss
  HOST = "wss://api.hadax.com/ws"

  class << self
    def run
      EM.run {
        # 如果需要挂代理，请用以下代码
        # ws = Faye::WebSocket::Client.new(HOST, [], proxy: {origin: "http://127.0.0.1:1087", ping: 5})
        ws = Faye::WebSocket::Client.new(HOST)

        ws.on :open do |event|
          puts "open"
          ws.send({id: 'hotbtc', sub: "market.hotbtc.kline.1min"}.to_json)
        end

        ws.on :message do |event|
          puts "message"
          data = event.data.pack('C*')

          begin
            # 由于对方加密是使用的是pako这个库
            # 如果被加密的是对象，则直接使用gunzip的方法进行解压
            # ruby 2.3.1没有集成gunzip方法，需要手动实现
            gz = Zlib::GzipReader.new(StringIO.new(data))
            json = gz.read
            content = JSON.parse(json)

            if content["ping"]
              ws.send({"pong": content["ping"]}.to_json)
            elsif content['tick']
              # do sth
              puts content
            else
              puts content
            end
          rescue => e
            # 如果被加密对象是被普通的值，则直接使用Zlib的inflate方法进行解压
            gz = Zlib::Inflate.inflate(data)
            content = JSON.parse(gz)

            puts content
          end
        end

        ws.on :close do |event|
          puts "close"
          # do sth to reconnect or notify yourself
          ws = nil
        end
      }
    end

    def my_logger
      @@my_logger ||= Logger.new("#{Rails.root}/log/hadax.log")
    end

    def log
      my_logger.info("log sth")
    end
  end
end

HadaxWss.run