require 'test/unit'
require 'rcsv'

class RcsvParseTest < Test::Unit::TestCase
  def setup
    @options = {
      :header => true,
      :columns => {
        'Date' => {
          :type => :string
        }
      }
    }
  end

  def test_rcsv_parse_unknown_rows
    csv = "a,b,c,d,e,f\n1,2,3,4,5,161226289488"
    parsed_data = Rcsv.parse(csv,
      :row_as_hash => true,
      :columns => {
        'b' => {
          :type => :int,
          :alias => 'B'
        },
        'd' => {
          :type => :int
        },
        'f' => {
          :type => :int
        }
      }
    )

    assert_equal({
      'a' => '1',
      'B' => 2,
      'c' => '3',
      'd' => 4,
      'e' => '5',
      'f' => 161226289488,
    }, parsed_data.first)
  end

  def test_rcsv_parse_only_rows
    csv = "a,1,t\nb,2,false\nc,3,0"
    parsed_data = Rcsv.parse(csv,
      :header => :none,
      :columns => [
        {
          :match => ['z', 'a', '1']
        },
        {},
        {
          :match => true,
          :type => :bool
        }
      ]
    )

    assert_equal([["a", "1", true]], parsed_data)
  end

  def test_rcsv_parse_only_rows_not_match
    csv = "a,1,t,8\nb,2,false,10000000000\nc,3,0,99999999999999\nd,14,false,161226289488"
    parsed_data = Rcsv.parse(csv,
      :header => :none,
      :columns => [
        {
          :not_match => ['z', 'a', '1']
        },
        {
          :type => :int
        },
        {
          :not_match => true,
          :type => :bool
        },
        {
          :not_match => 161226289488,
          :type => :int
        },
      ]
    )

    assert_equal([["b", 2, false, 10000000000], ["c", 3, false, 99999999999999]], parsed_data)
  end

  def test_rcsv_non_file_io_object
    csv, writer = IO.pipe

    writer.write("a,b,c\n1,2,3\n")
    writer.close

    parsed_data = Rcsv.parse(csv,
      :header => :use,
      :row_as_hash => true,
      :columns => {}
    )
    assert_equal({
      'a' => '1',
      'b' => '2',
      'c' => '3'
    }, parsed_data.first)
  end

  if String.instance_methods.include?(:encoding)
    def test_rcsv_parse_encoding
      utf8_csv = "a,b,c".force_encoding("UTF-8")
      ascii_csv = "a,b,c".force_encoding("ASCII-8BIT")

      parsed_utf8_data = Rcsv.parse(utf8_csv, :header => :none)
      parsed_ascii_data = Rcsv.parse(ascii_csv, :header => :none)

      assert_equal(parsed_utf8_data.first.first.encoding, Encoding::UTF_8)
      assert_equal(parsed_ascii_data.first.first.encoding, Encoding::ASCII_8BIT)
    end
  end
end
