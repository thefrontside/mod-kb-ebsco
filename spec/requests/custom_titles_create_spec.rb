# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom Titles Create', type: :request do
  let(:create_headers) do
    okapi_headers.merge(
      'Content-Type': 'application/vnd.api+json'
    )
  end

  let(:payload) do
    {
      'data'=> {
        'type'=> 'titles',
        'attributes'=> {
          'name'=> 'Beetlegeuce Test Title',
          'edition'=> '',
          'publisherName'=> '',
          'publicationType'=> 'Journal',
          'isPeerReviewed'=> false,
          'contributors'=> [],
          'identifiers'=> [],
          'description'=> ''
        }
      },
      'included'=> [
        {
          'type'=> 'resources',
          'attributes'=> {
            'packageId'=> '123355-2918760'
          }
        }
      ]
    }
  end

  describe 'with minimum required fields' do
    before do
      VCR.use_cassette('post-custom-title-name-pubtype') do
        post '/eholdings/titles',
             params: payload, as: :json, headers: create_headers
      end
    end

    it 'responds with OK status' do
      p response.body
      expect(response).to have_http_status(200)
    end

    let(:json) { Map JSON.parse response.body }
    let(:attributes) { json.data.attributes }

    it 'has a list of attributes' do
      expect(attributes).to include(
        'contributors',
        'description',
        'identifiers',
        'isPeerReviewed',
        'isTitleCustom',
        'name',
        'publicationType',
        'publisherName',
        'subjects'
      )
    end

    it 'has the new name' do
      expect(json.data.attributes.name).to eq('Beetlegeuce Test Title')
    end

    it 'has the new publication type' do
      expect(json.data.attributes.publicationType).to eq('Journal')
    end

    it 'has the newly generated id' do
      expect(json.data.id).to eq('18277752')
    end
  end

  describe 'with an existing name' do
    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'publicationType' => 'Book'
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-existing-name') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'responds with bad request' do
      expect(response).to have_http_status(400)
      expect(json.errors.first.title).to eql('Custom Title with the provided name already exists')
    end
  end

  describe 'with missing name' do
    before do
      params = payload
      params.data.attributes.delete('name')

      VCR.use_cassette('post-custom-title-missing-name') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid titleName')
    end
  end

  describe 'with a name that exceeds maximum size' do
    let(:largeName) { '0' * 401 }

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'name' => largeName
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-long-name') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid titleName')
    end
  end

  describe 'with missing publication type' do

    before do
      params = payload
      params.data.attributes.delete('publicationType')

      VCR.use_cassette('post-custom-title-missing-pubtype') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid pubType')
    end
  end

  describe 'with publication type outside list of known values' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'name' => 'Bears Test Title',
              'publicationType' => 'Made Up'
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-pubtype') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    it 'responds with OK status' do
      expect(response).to have_http_status(200)
    end

    let!(:json) { Map JSON.parse response.body }
    let!(:attributes) { json.data.attributes }

    it 'has unspecified publication type' do
      expect(json.data.attributes.publicationType).to eq('Unspecified')
    end
  end

  describe 'with missing included resource' do

    before do
      params = payload
      params.delete('included')

      VCR.use_cassette('post-custom-title-missing-resource') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(400)
      expect(json.errors.first.title).to eql('Missing resource')
    end
  end

  describe 'with missing package id' do

    before do
      params = payload
      params.included[0].delete('packageId')

      VCR.use_cassette('post-custom-title-missing-packageId') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid packageId')
    end
  end

  describe 'with a managed package id' do

    before do
      params = payload
      params.included[0].attributes.packageId = '123355-2512592'

      VCR.use_cassette('post-custom-title-managed-packageId') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(400)
      expect(json.errors.first.title).to eql('Custom Title can not be added to the provided package')
    end
  end

  describe 'with invalid package id' do

    before do
      params = payload
      params.included[0].attributes.packageId = '9999999-9999999'

      VCR.use_cassette('post-custom-title-invalid-packageId') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(404)
      expect(json.errors.first.title).to eql('Provider not found')
    end
  end

  describe 'with all fields' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'name' => 'Fallout Title Testing All Fields',
              'publicationType' => 'Book',
              'publisherName' => 'test publisher',
              'isPeerReviewed' => true,
              'edition' => 'test edition',
              'description' => 'test description',
              'contributors': [
                {
                  'type': 'Editor',
                  'contributor': 'some editor'
                },
                {
                  'type': 'Illustrator',
                  'contributor': 'some illustrator'
                }
              ],
              'identifiers': [
                {
                  'id': '12347',
                  'type': 'ISBN',
                  'subtype': 'Print'
                },
                {
                  'id': '98547',
                  'type': 'ISSN',
                  'subtype': 'Online'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-all-fields') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    it 'responds with OK status' do
      expect(response).to have_http_status(200)
    end

    let!(:json) { Map JSON.parse response.body }
    let!(:attributes) { json.data.attributes }

    it 'has the new resource name' do
      expect(json.data.attributes.name).to eq('Fallout Title Testing All Fields')
    end

    it 'has the new publicationType' do
      expect(json.data.attributes.publicationType).to eq('Book')
    end

    it 'has the new publisherName' do
      expect(json.data.attributes.publisherName).to eq('test publisher')
    end

    it 'has the new isPeerReviewed' do
      expect(json.data.attributes.isPeerReviewed).to eq(true)
    end

    it 'has the new edition' do
      expect(json.data.attributes.edition).to eq('test edition')
    end

    it 'has the new description' do
      expect(json.data.attributes.description).to eq('test description')
    end

    it 'has the list of contributors' do
      expect(json.data.attributes.contributors[0].type)
        .to eq('editor')
      expect(json.data.attributes.contributors[0].contributor)
        .to eq('some editor')
      expect(json.data.attributes.contributors[1].type)
        .to eq('illustrator')
      expect(json.data.attributes.contributors[1].contributor)
        .to eq('some illustrator')
    end

    it 'has the list of identifiers' do
      expect(json.data.attributes.identifiers[0].id)
        .to eq('12347')
      expect(json.data.attributes.identifiers[0].type)
        .to eq('ISBN')
      expect(json.data.attributes.identifiers[0].subtype)
        .to eq('Print')
      expect(json.data.attributes.identifiers[1].id)
        .to eq('98547')
      expect(json.data.attributes.identifiers[1].type)
        .to eq('ISSN')
      expect(json.data.attributes.identifiers[1].subtype)
        .to eq('Online')
    end
  end

  describe 'with publisher name that exceeds maximum size' do
    let(:largePublisherName) { '0' * 251 }

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'publisherName' => largePublisherName
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-long-publishername') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid publisherName')
    end
  end

  describe 'with peer reviewed that is not true/false' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'isPeerReviewed' => 'invalid'
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-peer-review') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid isPeerReviewed')
    end
  end

  describe 'with edition that exceeds maximum size' do
    let(:largeEdition) { '0' * 251 }

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'edition' => largeEdition
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-long-edition') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid edition')
    end
  end

  describe 'with description that exceeds maximum size' do
    let(:largeDescription) { '0' * 1501 }

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'description' => largeDescription
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-long-description') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
      expect(json.errors.first.title).to eql('Invalid description')
    end
  end

  describe 'with invalid contributor type' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'contributors': [
                {
                  'type': 'invalid type',
                  'contributor': 'some editor'
                },
                {
                  'type': 'Illustrator',
                  'contributor': 'some illustrator'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-contributor-type') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(400)
    end

    it 'returns expected error message' do
      expect(json.errors.first.title).to eql('Parameter contributorsList.contributorType must be one of (author, editor, illustrator).')
    end
  end

  describe 'with invalid identifier id' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'identifiers': [
                {
                  'id': 12_345, # cannot be an integer, has to be a string
                  'type': 'ISBN',
                  'subtype': 'Print'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-identifier-id') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid IdentifierId')
    end
  end

  describe 'with invalid identifier id length' do
    let(:longIdentifierId) { '0' * 21 }

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'identifiers': [
                {
                  'id': longIdentifierId,
                  'type': 'ISBN',
                  'subtype': 'Print'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-identifier-id-length') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid IdentifierId')
    end
  end

  describe 'with missing identifier id' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'identifiers': [
                {
                  'type': 'ISBN',
                  'subtype': 'Print'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-missing-identifier-id') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid IdentifierId')
    end
  end

  describe 'with invalid identifier type' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'identifiers': [
                {
                  'id': '12345',
                  'type': 'Invalid Type',
                  'subtype': 'Print'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-identifier-type') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid IdentifierType')
    end
  end

  describe 'with valid identifier types' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'name' => 'Davis Test Valid Identifier Types',
              'identifiers': [
                {
                  'id': '12345',
                  'type': 'ISSN',
                  'subtype': 'Print'
                },
                {
                  'id': '12345',
                  'type': 'ISBN',
                  'subtype': 'Print'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-valid-identifier-types') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'responds with OK status' do
      expect(response).to have_http_status(200)
    end

    let!(:json) { Map JSON.parse response.body }
    let!(:attributes) { json.data.attributes }

    it 'has the expected list of identifiers' do
      expect(json.data.attributes.identifiers[0].id)
        .to eq('12345')
      expect(json.data.attributes.identifiers[0].type)
        .to eq('ISSN')
      expect(json.data.attributes.identifiers[0].subtype)
        .to eq('Print')
      expect(json.data.attributes.identifiers[1].id)
        .to eq('12345')
      expect(json.data.attributes.identifiers[1].type)
        .to eq('ISBN')
      expect(json.data.attributes.identifiers[1].subtype)
        .to eq('Print')
    end
  end

  describe 'with invalid identifier subtype' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'identifiers': [
                {
                  'id': '12345',
                 'type': 'ISSN',
                 'subtype': 'Invalid subtype'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-invalid-identifier-type') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid IdentifierSubType')
    end
  end

  describe 'with valid identifier subtypes' do

    before do
      params = payload.merge(
        {
          'data' => {
            'attributes' => {
              'name' => 'Hagrid Valid Subtype',
              'identifiers': [
                {
                  'id': '12345',
                  'type': 'ISSN',
                  'subtype': 'Print'
                },
                {
                  'id': '12345',
                  'type': 'ISBN',
                  'subtype': 'Online'
                }
              ]
            }
          }
        }
      )

      VCR.use_cassette('post-custom-title-valid-identifier-subtypes') do
        post '/eholdings/titles',
             params: params, as: :json, headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'responds with OK status' do
      expect(response).to have_http_status(200)
    end

    let!(:json) { Map JSON.parse response.body }
    let!(:attributes) { json.data.attributes }

    it 'has the expected list of identifiers' do
      expect(json.data.attributes.identifiers[0].id)
        .to eq('12345')
      expect(json.data.attributes.identifiers[0].type)
        .to eq('ISSN')
      expect(json.data.attributes.identifiers[0].subtype)
        .to eq('Print')
      expect(json.data.attributes.identifiers[1].id)
        .to eq('12345')
      expect(json.data.attributes.identifiers[1].type)
        .to eq('ISBN')
      expect(json.data.attributes.identifiers[1].subtype)
        .to eq('Online')
    end
  end

  describe 'with an invalid payload' do
    before do
      VCR.use_cassette('post-custom-title-invalid-payload') do
        post '/eholdings/titles', headers: create_headers
      end
    end

    let!(:json) { Map JSON.parse response.body }

    it 'returns an error status' do
      expect(response).to have_http_status(422)
    end

    it 'returns expected error message title' do
      expect(json.errors.first.title).to eql('Invalid JSON')
    end
  end
end
