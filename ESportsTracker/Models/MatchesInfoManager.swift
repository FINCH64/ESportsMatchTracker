//
//  MatchesInfoManager.swift
//  ESportsTracker
//
//  Created by f1nch on 15.11.23.
//

import Foundation

//менеджер запросов и обработки информации об идущих матчах(сетевой слой и обработка результатов)

class MatchesInfoManager {
    static let shared = MatchesInfoManager()
    var matchesModel = MatchesInfoModel.shared
    
    private init(){}
    
    func updateAllCurrentLiveMatches(updateAllMatchesTable: Bool) {
        //должен делать запрос к апи за текущими матчами,загружает данные асинхронно
        //при окончании создает в главном потоке задачу обновления UITableView и всех ячеек

        DispatchQueue.global(qos: .userInteractive).async(flags: .barrier) {
            let headers = [
                "X-RapidAPI-Key": "af06df5541msh49a64a9df42bb9cp153137jsn4398a4d33471",
                "X-RapidAPI-Host": "esportapi1.p.rapidapi.com"
            ]
            
            let request = NSMutableURLRequest(url: NSURL(string: "https://esportapi1.p.rapidapi.com/api/esport/matches/live")! as URL,
                                              cachePolicy: .useProtocolCachePolicy,
                                              timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    print(error as Any)
                } else {
                    do {
                        print(response as? HTTPURLResponse ?? "no server response")
                        self.matchesModel.liveMatchesInfo = try JSONDecoder().decode(LiveMatches.self, from: data!)
                        self.getLiveCSMatches(from: self.matchesModel.liveMatchesInfo?.events)
                        if updateAllMatchesTable == true {
                            //обновить все ячейки TableView синхронно в главном потоке
                            DispatchQueue.main.sync {
                                self.matchesModel.updateTVLiveMatchesCells()
                            }
                        }
                    } catch let parsingError as NSError {
                        print(parsingError.localizedDescription)
                    }
                }
            })
            dataTask.resume()
        }
    }
    
    //метод подгрузки лэйбла команды(картинки) по её id,внутренности будут работать и будут закомменчены чтобы не тратить запросы
    //indexPath нужен чтобы было понятно в каком ряду искать UIImage для вставки загруженных картинок
    func getTeamImage(teamId id: Int,indexPath: IndexPath) {
        DispatchQueue.global(qos: .default).async {
            let headers = [
                "X-RapidAPI-Key": "af06df5541msh49a64a9df42bb9cp153137jsn4398a4d33471",
                "X-RapidAPI-Host": "esportapi1.p.rapidapi.com"
            ]
            
            let request = NSMutableURLRequest(url: NSURL(string: "https://esportapi1.p.rapidapi.com/api/esport/team/364623/image")! as URL,
                                              cachePolicy: .useProtocolCachePolicy,
                                              timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    print(error as Any)
                } else {
                    print(response as? HTTPURLResponse ?? "no server response")
                    DispatchQueue.main.sync {
                        self.matchesModel.updateCellsTeamImages(imageData: data ?? Data(),indexPath: indexPath,logoTeamId: id)
                    }
                }
            })
            
            dataTask.resume()
        }
    }
    
    //метод вызывающий через модель-презентер-вью обновление всех ячеек,вызывается после асинхронной загрузки данных о матчах
    private func getLiveCSMatches(from matches: [Event]?) {
        //выбирает все матчи по кс и записывает в переменную внутри модели
        if let matches = matches {
            self.matchesModel.liveCsMatchesInfo = matches.filter{$0.tournament?.category?.flag == Flag.csgo}
        }
    }
}
