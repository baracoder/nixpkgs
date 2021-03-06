{ stdenv, buildPythonPackage, fetchPypi
, flask, flask_wtf, flask_testing, ldap
, mock, nose }:

buildPythonPackage rec {
  pname = "flask-ldap-login";
  version = "0.3.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "085rik7q8xrp5g95346p6jcp9m2yr8kamwb2kbiw4q0b0fpnnlgq";
  };

  checkInputs = [ nose mock flask_testing ];
  propagatedBuildInputs = [ flask flask_wtf ldap ];

  checkPhase = "nosetests -d";

  meta = with stdenv.lib; {
    homepage = https://github.com/ContinuumIO/flask-ldap-login;
    description = "User session management for Flask";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ mic92 ];
  };
}
