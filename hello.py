import flask from Flask

app= Flask(__name__)
def hello_world():
    return "hello ravi"

if __name__=="__main__":
    app.run(debug=True, port=8000)