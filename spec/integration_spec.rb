require 'active_support/all'
require 'mumukit/bridge'

def format(result)
  Mumukit::ContentType::Markdown.code result
end

describe 'Server' do
  let(:bridge) { Mumukit::Bridge::Runner.new('http://localhost:4568') }

  before(:all) do
    @pid = Process.spawn 'rackup -p 4568', err: '/dev/null'
    sleep 8
  end
  after(:all) { Process.kill 'TERM', @pid }

  it 'answers a valid hash when submission passes' do
    response = bridge.run_tests!(test: %q{
@Test
public void testFoo() {
  Assert.assertEquals(Foo.bar(), 2);
}}, extra: '', content: %q{
class Foo {
  public static int bar() {
    return 2;
  }
}}, expectations: [])

    expect(response).to eq(response_type: :structured,
                           test_results: [{title: 'testFoo', status: :passed, result: nil}],
                           status: :passed,
                           feedback: '',
                           expectation_results: [],
                           result: '')
  end


  it 'supports multiple files' do
    response = bridge.run_tests!(test: %q{
@Test
public void email_admite_elaborar() {
  Email email = new Email(
    new Destinatario("Juan Perez", "juanperez@gmail.com"),
    "Hola juan!!"
  );
  Assert.assertEquals("Para: Juan Perez <juanperez@gmail.com>\\nHola juan!!", email.elaborar());
}}, extra: '', content: %q{
/*<Email.java#*/
public class Email {
  private Destinatario destinatario;
  private String cuerpo;

  public Email(Destinatario destinatario, String cuerpo) {
    this.destinatario = destinatario;
    this.cuerpo = cuerpo;
  }

  String elaborar() {
    return "Para: " + this.destinatario.elaborarEncabezado() + "\\n" + this.cuerpo;
  }
}
/*#Email.java>*/

/*<Destinatario.java#*/
public class Destinatario {
        private String nombre;
        private String email;

        public Destinatario(String nombre, String email) {
                this.nombre = nombre;
                this.email = email;
        }

    String elaborarEncabezado() {
      return this.nombre + " <" + this.email + ">";
    }
}
/*#Destinatario.java>*/
}, expectations: [{'binding' => 'Email',
                    'inspection' => 'DeclaresMethod:elaborar'},
                   {'binding' => 'Destinatario',
                    'inspection' => 'DeclaresMethod:elaborarEncabezado'}])

    expect(response).to eq(response_type: :structured,
                           test_results: [{ title: 'email_admite_elaborar', status: :passed, result: nil }],
                           status: :passed,
                           feedback: '',
                           expectation_results: [
                               {:binding=>"Email", :inspection=>"DeclaresMethod:elaborar", :result=>:passed},
                               {:binding=>"Destinatario", :inspection=>"DeclaresMethod:elaborarEncabezado", :result=>:passed}
                           ],
                           result: '')
  end

  it 'answers a valid hash when submission fails' do
    response = bridge.run_tests!(test: %q{
@Test
public void testFoo() {
  Assert.assertEquals(Foo.bar(), 2);
}}, extra: '', content: %q{
class Foo {
  public static int bar() {
    return 2;
  }
}}, expectations: [])

    expect(response).to eq(response_type: :structured,
                           test_results: [{title: 'testFoo', status: :passed, result: nil}],
                           status: :passed,
                           feedback: '',
                           expectation_results: [],
                           result: '')
  end
end
