# encoding: utf-8
module CarrierWave
  module Workers

    module StoreAssetMixin
      require 'open-uri'
      include CarrierWave::Workers::Base

      def self.included(base)
        base.extend CarrierWave::Workers::ClassMethods
      end

      attr_reader :cache_path, :tmp_directory

      def perform(*args)
        record = super(*args)

        if record && record.send(:"#{column}_tmp")
          store_directories(record)
          record.send :"process_#{column}_upload=", true
          record.send :"#{column}_tmp=", nil
          record.send :"#{column}_processing=", false if record.respond_to?(:"#{column}_processing")
          File.open(cache_path) { |f| record.send :"#{column}=", f }
          if record.save!
            FileUtils.rm_r(tmp_directory, :force => true)
          end
        else
          when_not_ready
        end
      end

      private

      def store_directories(record)
        asset, asset_tmp = record.send(:"#{column}"), record.send(:"#{column}_tmp")
        cache_directory  = File.expand_path(asset.cache_dir, asset.root)
        if Rails.env.production?
          @cache_path      = open("https://wire-files.s3.amazonaws.com/#{asset_tmp}")
        elsif Rails.env.staging?
          @cache_path      = open("https://wire-files-staging.s3.amazonaws.com/#{asset_tmp}")
        else
          @cache_path      = File.join(cache_directory, asset_tmp)
        end
        @tmp_directory   = File.join(cache_directory, asset_tmp.split("/").first)
      end

    end # StoreAssetMixin

  end # Workers
end # Backgrounder
