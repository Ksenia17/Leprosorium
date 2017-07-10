require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
  @db = SQLite3::Database.new'leprosorium.db'
  @db.results_as_hash = true
end

before do
  # инициализация БД
  init_db
end  

configure do
 # enable :sessions
 # инициализация БД
 init_db
 # создает таблицу Posts, если она не существует
 @db.execute 'CREATE TABLE IF NOT EXISTS Posts
           ( 
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             created_date TEXT,
             content TEXT
           )'
  # создает таблицу Comments, если она не существует         
  @db.execute 'CREATE TABLE IF NOT EXISTS Comments
           ( 
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             created_date TEXT,
             content TEXT,
             post_id integer
           )'         



end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  # выбираем список постов
  
  @rezults = @db.execute 'select * from Posts order by id desc'
  
  erb :index
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end

get '/new' do
  erb :new
end

post '/new' do
  content = params[:content]

  if content.length <= 0
    @error = 'Type post text'
    return erb :new
  end  
  #  сохранение данных в БД
  @db.execute 'insert into Posts (content,created_date) values (?,datetime())',[content]
  
  # перенаправление на главную страницу
  redirect to '/'  
end

get '/details/:post_id' do
  post_id = params[:post_id]

  @results = @db.execute 'select * from Posts where id=?',"#{post_id}"
  
  @row = @results[0]


  #выбираем комментарии для нашего поста
  @comments = @db.execute 'select * from Comments where post_id=? order by id', [post_id]


  erb :details
end  

# обработчик  post-запроса для /details/...
# браузер отправляет данные на сервер, мы их принимаем
post '/details/:post_id' do
 # получаем переменную из url'a
  post_id = params[:post_id]
 # получаем переменную из  post-запроса
  content = params[:content]

#  сохранение данных в БД
  @db.execute 'insert into Comments 
              (
              content,
              created_date,
              post_id
              )
              values
              (
              ?,
              datetime(),
              ?
              )',[content,post_id]
  
  # перенаправление на страницу поста
  # save comment to database
  redirect to ('/details/'+post_id)  

end 
