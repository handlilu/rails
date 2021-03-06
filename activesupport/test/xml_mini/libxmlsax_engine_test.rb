begin
  require "libxml"
rescue LoadError
  # Skip libxml tests
else
  require "abstract_unit"
  require "active_support/xml_mini"
  require "active_support/core_ext/hash/conversions"

  class LibXMLSAXEngineTest < ActiveSupport::TestCase
    include ActiveSupport

    def setup
      @default_backend = XmlMini.backend
      XmlMini.backend = "LibXMLSAX"
    end

    def teardown
      XmlMini.backend = @default_backend
    end

    def test_exception_thrown_on_expansion_attack
      assert_raise LibXML::XML::Error do
        attack_xml = <<-EOT
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE member [
        <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
        <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
        <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
        <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
        <!ENTITY e "&f;&f;&f;&f;&f;&f;&f;&f;&f;&f;">
        <!ENTITY f "&g;&g;&g;&g;&g;&g;&g;&g;&g;&g;">
        <!ENTITY g "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">
      ]>
      <member>
      &a;
      </member>
      EOT

        Hash.from_xml(attack_xml)
      end
    end

    def test_setting_libxml_as_backend
      XmlMini.backend = "LibXMLSAX"
      assert_equal XmlMini_LibXMLSAX, XmlMini.backend
    end

    def test_blank_returns_empty_hash
      assert_equal({}, XmlMini.parse(nil))
      assert_equal({}, XmlMini.parse(""))
    end

    def test_array_type_makes_an_array
      assert_equal_rexml(<<-eoxml)
      <blog>
        <posts type="array">
          <post>a post</post>
          <post>another post</post>
        </posts>
      </blog>
    eoxml
    end

    def test_one_node_document_as_hash
      assert_equal_rexml(<<-eoxml)
      <products/>
      eoxml
    end

    def test_one_node_with_attributes_document_as_hash
      assert_equal_rexml(<<-eoxml)
      <products foo="bar"/>
      eoxml
    end

    def test_products_node_with_book_node_as_hash
      assert_equal_rexml(<<-eoxml)
    <products>
      <book name="awesome" id="12345" />
    </products>
    eoxml
    end

    def test_products_node_with_two_book_nodes_as_hash
      assert_equal_rexml(<<-eoxml)
    <products>
      <book name="awesome" id="12345" />
      <book name="america" id="67890" />
    </products>
    eoxml
    end

    def test_single_node_with_content_as_hash
      assert_equal_rexml(<<-eoxml)
      <products>
        hello world
      </products>
    eoxml
    end

    def test_children_with_children
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>
        <book name="america" id="67890" />
      </products>
    </root>
    eoxml
    end

    def test_children_with_text
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>
        hello everyone
      </products>
    </root>
    eoxml
    end

    def test_children_with_non_adjacent_text
      assert_equal_rexml(<<-eoxml)
    <root>
      good
      <products>
        hello everyone
      </products>
      morning
    </root>
    eoxml
    end

    def test_parse_from_io
      io = StringIO.new(<<-eoxml)
    <root>
      good
      <products>
        hello everyone
      </products>
      morning
    </root>
    eoxml
      assert_equal_rexml(io)
    end

    def test_children_with_simple_cdata
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>
         <![CDATA[cdatablock]]>
      </products>
    </root>
    eoxml
    end

    def test_children_with_multiple_cdata
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>
         <![CDATA[cdatablock1]]><![CDATA[cdatablock2]]>
      </products>
    </root>
    eoxml
    end

    def test_children_with_text_and_cdata
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>
        hello <![CDATA[cdatablock]]>
        morning
      </products>
    </root>
    eoxml
    end

    def test_children_with_blank_text
      assert_equal_rexml(<<-eoxml)
    <root>
      <products>   </products>
    </root>
    eoxml
    end

    private
      def assert_equal_rexml(xml)
        parsed_xml = XmlMini.parse(xml)
        xml.rewind if xml.respond_to?(:rewind)
        hash = XmlMini.with_backend("REXML") { XmlMini.parse(xml) }
        assert_equal(hash, parsed_xml)
      end
  end

end
