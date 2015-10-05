require 'spec_helper'

describe Griddler::Postmark::Adapter, '.normalize_params' do
  it_should_behave_like 'Griddler adapter', :postmark,
    {
      FromFull: {
        Email: 'there@example.com',
        Name: 'There',
      },
      ToFull: [{
        Email: 'hi@example.com',
        Name: 'Hello World',
      }],
      CcFull: [{
        Email: 'emily@example.com',
        Name: '',
      }],
      BccFull: [{
        Email: 'mary@example.com',
        Name: 'Mary',
      }],
      TextBody: 'hi',
    }

  it 'normalizes parameters' do
    expect(Griddler::Postmark::Adapter.normalize_params(default_params)).to be_normalized_to({
      to: ['Robert Paulson <bob@example.com>'],
      cc: ['Jack <jack@example.com>'],
      bcc: ['Mary <mary@example.com>'],
      from: 'Tyler Durden <tdurden@example.com>',
      subject: 'Reminder: First and Second Rule',
      text: /Dear bob/,
      html: %r{<p>Dear bob</p>},
      headers: {
        "Message-ID" => "<message-id@mail.gmail.com>"
      }
    })
  end

  it 'handles CcFull of nil' do
    no_cc_params = default_params
    no_cc_params[:CcFull] = nil
    normalized = Griddler::Postmark::Adapter.normalize_params(no_cc_params)

    expect(normalized[:cc]).to eq []
  end

  it 'passes the received array of files' do
    params = default_params.merge({ Attachments: [upload_1_params, upload_2_params] })

    normalized_params = Griddler::Postmark::Adapter.normalize_params(params)

    first, second = *normalized_params[:attachments]

    expect(first.original_filename).to eq('photo1.jpg')
    expect(first.size).to eq(upload_1_params[:ContentLength])

    expect(second.original_filename).to eq('photo2.jpg')
    expect(second.size).to eq(upload_2_params[:ContentLength])
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Postmark::Adapter.normalize_params(params)

    expect(normalized_params[:attachments]).to be_empty
  end

  it 'gets rid of the original postmark params' do
    expect(Griddler::Postmark::Adapter.normalize_params(default_params)).to be_normalized_to({
      ToFull: nil,
      FromFull: nil,
      CcFull: nil,
      Subject:  nil,
      TextBody: nil,
      HtmlBody: nil,
      Attachments: nil
    })
  end

  def default_params
    {
      FromFull: {
        Email: 'tdurden@example.com',
        Name: 'Tyler Durden'
      },
      ToFull: [{
        Email: 'bob@example.com',
        Name: 'Robert Paulson'
      }],
      CcFull: [{
        Email: 'jack@example.com',
        Name: 'Jack'
      }],
      BccFull: [{
        Email: 'mary@example.com',
        Name: 'Mary',
      }],
      Subject: 'Reminder: First and Second Rule',
      TextBody: text_body,
      HtmlBody: text_html,
      Headers: [
        {
          Name: "Message-ID",
          Value: "<message-id@mail.gmail.com>"
        }
      ]
    }
  end

  def text_body
    <<-EOS.strip_heredoc.strip
      Dear bob

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def text_html
    <<-EOS.strip_heredoc.strip
      <p>Dear bob</p>

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def upload_1_params
    @upload_1_params ||= begin
      file = fixture_file('photo1.jpg')
      {
        Name: 'photo1.jpg',
        Content: Base64.encode64(file.read),
        ContentType: 'image/jpeg',
        ContentLength: file.size
      }
    end
  end

  def upload_2_params
    @upload_2_params ||= begin
      file = fixture_file('photo2.jpg')
      {
        Name: 'photo2.jpg',
        Content: Base64.encode64(file.read),
        ContentType: 'image/jpeg',
        ContentLength: file.size
      }
    end
  end

  def fixture_file(name)
    cwd = File.expand_path File.dirname(__FILE__)
    File.new(File.join(cwd, '..', '..', 'fixtures', name))
  end
end
