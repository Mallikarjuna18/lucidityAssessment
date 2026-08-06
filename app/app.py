from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

if __name__ == '__main__':
    # host='0.0.0.0' is required to make the server accessible outside the container
    app.run(host='0.0.0.0', port=8080)