class Song < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    include Responder
    model Song, :create


    contract do
      property :title, validates: {presence: true}
      property :length
    end

    def process(params)
      validate(params[:song]) do
        contract.save
      end
    end
  end


  class Delete < Create
    action :find

    def process(params)
      model.destroy
      self
    end
  end
end

class Band < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD, Responder
    model Band, :create

    contract do
      include Reform::Form::ActiveModel
      model Band

      property :name, validates: {presence: true}
      property :locality

      # class: Song #=> always create new song
      # instance: { Song.find(params[:id]) or Song.new } # same as find_or_create ?
      # this is what i want:
      # maybe make populate_if_empty a representable feature?
      collection :songs, populate_if_empty: Song do
        property :title
      end
    end

    def process(params)
      validate(params[:band]) do
        contract.save
      end
    end

    class JSON < self
      include Representer

      require "reform/form/json"
      contract do
        include Reform::Form::JSON # this allows deserialising JSON.
      end

      representer do
        collection :songs, inherit: true, render_empty: false # tested in ControllerPresentTest.
      end
    end

    builds do |params|
      JSON if params[:format] == "json"
    end
  end

  class Update < Create
    action :update

    # TODO: infer stuff per default.
    class JSON < self
      include Representer

      self.contract_class = Create::JSON.contract_class
      self.representer_class = Create::JSON.representer_class
    end

    builds do |params|
      JSON if params[:format] == "json"
    end
  end
end