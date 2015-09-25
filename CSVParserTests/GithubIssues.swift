//
//  GithubIssues.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
import CSVParser

class GithubIssues: XCTestCase {
    
    func testIssue1() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+FIELD3+COMMA+FIELD1+BACKSLASH
        
        var config = CSVParserConfiguration()
        config.recognizeBackslashAsEscape = true
        
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testIssue35() {
        let tsv = "1,a\t1,b\t1,c\t1,\"d\"\n" + "2,a\t2,b\t2,c\t2,d\n" + "3,a\t3,b\t3,c\t3,d\n" + "4,a\t4,b\t4,c\t4,d\n" + "5,a\t5,b\t5,c\t5,d\n" + "6,a\t6,b\t6,c\t6,d\n" + "7,a\t7,b\t7,c\t7,d\n" + "8,a\t8,b\t8,c\t8,d\n" + "9,a\t9,b\t9,c\t9,d\n" + "10,a\t10,b\t10,c\t10,d"
        
        let expected: Array<CSVRecord> = [
            ["1,a", "1,b", "1,c", "1,\"d\""],
            ["2,a", "2,b", "2,c", "2,d"],
            ["3,a", "3,b", "3,c", "3,d"],
            ["4,a", "4,b", "4,c", "4,d"],
            ["5,a", "5,b", "5,c", "5,d"],
            ["6,a", "6,b", "6,c", "6,d"],
            ["7,a", "7,b", "7,c", "7,d"],
            ["8,a", "8,b", "8,c", "8,d"],
            ["9,a", "9,b", "9,c", "9,d"],
            ["10,a", "10,b", "10,c", "10,d"],
        ]
        
        parse(tsv, expected, CSVParserConfiguration(delimiter: "\t"))
    }
    
    func testIssue38() {
        let csv = "\(Field1),\(Field2),\(Field3)\n#"
        let expected: Array<CSVRecord> = [[Field1, Field2, Field3]]
        
        var config = CSVParserConfiguration()
        config.recognizeComments = true
        parse(csv, expected, config)
    }
    
    func testIssue50() {
        let csv = "TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id"
        let expected: Array<CSVRecord> = [["TRẦN","species_code","Scientific name","Author name","Common name","Family","Description","Habitat","\"Leaf size min (cm, 0 decimal digit)\"","\"Leaf size max (cm, 0 decimal digit)\"","Distribution","Current National Conservation Status","Growth requirements","Horticultural features","Uses","Associated fauna","Reference","species_id"]]
        
        var configuration = CSVParserConfiguration()
        configuration.recognizeBackslashAsEscape = true
        parse(csv, expected, configuration)
    }
    
    func testIssue53() {
        let csv = "F1,F2,F3\n" + "a, \"b, B\",c\n" + "A,B,C\n" + "1,2,3\n" + "I,II,III"
        let expected: Array<CSVRecord> = [
            ["F1", "F2", "F3"],
            ["a", " \"b, B\"", "c"],
            ["A", "B", "C"],
            ["1", "2", "3"],
            ["I", "II", "III"]
        ]
        parse(csv, expected)
    }
    
    func testIssue64() {
        guard let fileURL = resource("Issue64") else { return }
        
        guard let source = XCTAssertNoThrows(try String(contentsOfURL: fileURL)) else { return }
        let expected: Array<CSVRecord> = [["SplashID vID File -v2.0"],
                        ["F"],
                        ["T","21","Web Logins","Description","Username","Password","URL","Field 5","4",""],
                        ["F","21","test","me","23123123","www.ya.ru","","","4","","","","","","","Personal","\"aasdasd\r\radasdasd\""],
                        ["T","3","Credit Cards","Description","Card #","Expiry Date","Name","PIN","18",""],
                        ["F","3","карта","123123123213","23/23","Лдлоло Лдлодло","23223","","18","","","","","","","Unfiled","\"фывфывыфв\r\r\rфывфыв\""],
                        ["T","21","Web Logins","Description","Username","Password","URL","Field 5","4",""],
                        ["F","21","test 2","me","23123123","www.ya.ru","f5","f6","4","","","","","","","Personal","\"aasdasd\r\radasdasd\""],
                        ["T","3","Credit Cards","Description","Card #","Expiry Date","Name","PIN","18",""],
                        ["F","3","карта 2","123123123213","23/23","Лдлоло Лдлодло","23223","","18","","","","","","","Unfiled","\"фывфывыфв\r\r\rфывфыв\""]]
    
        parse(source, expected)
    }
    
    func testIssue65() {
        guard let fileURL = resource("Issue65") else { return }
        
        guard let source = XCTAssertNoThrows(try String(contentsOfURL: fileURL, encoding: NSMacOSRomanStringEncoding)) else { return }
        let expected: Array<CSVRecord> = [["Bib", "Name", "Teamcode", "Team"],
                        ["71", "DUMOULIN Tom", "GIA", "TEAM GIANT-SHIMANO"],
                        ["41", "CANCELLARA Fabian", "TFR", "TREK FACTORY RACING"],
                        ["68", "THOMAS Geraint", "SKY", "TEAM SKY"],
                        ["37", "QUINZIATO Manuel", "BMC", "BMC RACING TEAM"],
                        ["46", "SERGENT Jesse", "TFR", "TREK FACTORY RACING"],
                        ["39", "CUMMINGS Stephen", "BMC", "BMC RACING TEAM"],
                        ["140", "GRIVKO Andriy", "AST", "ASTANA PRO TEAM"],
                        ["57", "MOSER Moreno", "CAN", "CANNONDALE"],
                        ["11", "BOOM Lars", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["34", "DENNIS Rohan", "BMC", "BMC RACING TEAM"],
                        ["33", "DILLIER Silvan", "BMC", "BMC RACING TEAM"],
                        ["5", "TERPSTRA Niki", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["36", "OSS Daniel", "BMC", "BMC RACING TEAM"],
                        ["16", "VAN EMDEN Jos", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["143", "DOWSETT Alex", "MOV", "MOVISTAR TEAM"],
                        ["104", "HEPBURN Michael", "OGE", "ORICA GreenEDGE"],
                        ["81", "LANGEVELD Sebastian", "GRS", "GARMIN SHARP"],
                        ["84", "NAVARDAUSKAS Ramunas", "GRS", "GARMIN SHARP"],
                        ["86", "VAN BAARLE Dylan", "GRS", "GARMIN SHARP"],
                        ["53", "KOREN Kristijan", "CAN", "CANNONDALE"],
                        ["127", "SMUKULIS Gatis", "KAT", "TEAM KATUSHA"],
                        ["1", "STYBAR Zdenek", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["31", "GILBERT Philippe", "BMC", "BMC RACING TEAM"],
                        ["184", "LAMPAERT Yves", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["44", "HONDO Danilo", "TFR", "TREK FACTORY RACING"],
                        ["88", "MILLAR David", "GRS", "GARMIN SHARP"],
                        ["106", "KEUKELEIRE Jens", "OGE", "ORICA GreenEDGE"],
                        ["61", "BOASSON HAGEN Edvald", "SKY", "TEAM SKY"],
                        ["38", "VAN AVERMAET Greg", "BMC", "BMC RACING TEAM"],
                        ["74", "GESCHKE Simon", "GIA", "TEAM GIANT-SHIMANO"],
                        ["125", "PORSEV Alexandr", "KAT", "TEAM KATUSHA"],
                        ["64", "KNEES Christian", "SKY", "TEAM SKY"],
                        ["17", "VANMARCKE Sep", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["124", "KUZNETSOV Viacheslav", "KAT", "TEAM KATUSHA"],
                        ["82", "BAUER Jack", "GRS", "GARMIN SHARP"],
                        ["8", "VERMOTE Julien", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["7", "VAN KEIRSBULCK Guillaume", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["43", "DEVOLDER Stijn", "TFR", "TREK FACTORY RACING"],
                        ["28", "WELLENS Tim", "LTB", "LOTTO BELISOL"],
                        ["121", "BRUTT Pavel", "KAT", "TEAM KATUSHA"],
                        ["107", "MOURIS Jens", "OGE", "ORICA GreenEDGE"],
                        ["161", "APPOLLONIO Davide", "ALM", "AG2R LA MONDIALE"],
                        ["145", "VENTOSO ALBERDI Francisco Jose", "MOV", "MOVISTAR TEAM"],
                        ["148", "SÜTTERLIN Jasha", "MOV", "MOVISTAR TEAM"],
                        ["75", "JANSE VAN RENSBURG Reinardt", "GIA", "TEAM GIANT-SHIMANO"],
                        ["21", "GREIPEL André", "LTB", "LOTTO BELISOL"],
                        ["186", "VAN HOECKE Gijs", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["116", "ROUX Anthony", "FDJ", "FDJ.fr"],
                        ["141", "GUTIERREZ PALACIOS José Ivan", "MOV", "MOVISTAR TEAM"],
                        ["96", "ROVNI Ivan", "TCS", "TINKOFF-SAXO"],
                        ["23", "BROECKX Stig", "LTB", "LOTTO BELISOL"],
                        ["166", "GOUGEARD Alexis", "ALM", "AG2R LA MONDIALE"],
                        ["122", "IGNATYEV Mikhail", "KAT", "TEAM KATUSHA"],
                        ["112", "BOUCHER David", "FDJ", "FDJ.fr"],
                        ["109", "HOWARD Leigh", "OGE", "ORICA GreenEDGE"],
                        ["65", "ROWE Luke", "SKY", "TEAM SKY"],
                        ["48", "VAN POPPEL Danny", "TFR", "TREK FACTORY RACING"],
                        ["15", "TANKINK Bram", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["24", "ROELANDTS Jurgen", "LTB", "LOTTO BELISOL"],
                        ["178", "NAULEAU Bryan", "EUC", "TEAM EUROPCAR"],
                        ["4", "STEEGMANS Gert", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["69", "PUCCIO Salvatore", "SKY", "TEAM SKY"],
                        ["85", "NUYENS Nick", "GRS", "GARMIN SHARP"],
                        ["199", "DE TROYER Tim", "WGG", "WANTY - GROUPE GOBERT"],
                        ["128", "TCATEVICH Alexsei", "KAT", "TEAM KATUSHA"],
                        ["25", "SIEBERG Marcel", "LTB", "LOTTO BELISOL"],
                        ["6", "TRENTIN Matteo", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["154", "CIMOLAI Davide", "LAM", "LAMPRE-MERIDA"],
                        ["18", "WYNANTS Maarten", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["2", "BOONEN Tom", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["188", "WAEYTENS Zico", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["198", "DRUCKER Jean-Pierre", "WGG", "WANTY - GROUPE GOBERT"],
                        ["55", "MARCATO Marco", "CAN", "CANNONDALE"],
                        ["153", "POZZATO Filippo", "LAM", "LAMPRE-MERIDA"],
                        ["94", "MCCARTHY Jay", "TCS", "TINKOFF-SAXO"],
                        ["87", "HAAS Nathan", "GRS", "GARMIN SHARP"],
                        ["123", "KOCHETKOV Pavel", "KAT", "TEAM KATUSHA"],
                        ["83", "FARRAR Tyler", "GRS", "GARMIN SHARP"],
                        ["114", "OFFREDO Yoann", "FDJ", "FDJ.fr"],
                        ["95", "PETROV Evgeny", "TCS", "TINKOFF-SAXO"],
                        ["3", "KEISSE Iljo", "OPQ", "OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                        ["105", "HOWSON Damien", "OGE", "ORICA GreenEDGE"],
                        ["52", "BETTIOL Alberto", "CAN", "CANNONDALE"],
                        ["157", "RICHEZE Maximiliano Ariel", "LAM", "LAMPRE-MERIDA"],
                        ["196", "SELVAGGI Mirko", "WGG", "WANTY - GROUPE GOBERT"],
                        ["164", "GASTAUER Ben", "ALM", "AG2R LA MONDIALE"],
                        ["117", "SOUPE Geoffrey", "FDJ", "FDJ.fr"],
                        ["47", "VAN POPPEL Boy", "TFR", "TREK FACTORY RACING"],
                        ["66", "STANNARD Ian", "SKY", "TEAM SKY"],
                        ["192", "VEUCHELEN Frederik", "WGG", "WANTY - GROUPE GOBERT"],
                        ["160", "POLANC Jan", "LAM", "LAMPRE-MERIDA"],
                        ["162", "BAGDONAS Gediminas", "ALM", "AG2R LA MONDIALE"],
                        ["195", "DE VREESE Laurens", "WGG", "WANTY - GROUPE GOBERT"],
                        ["26", "VANENDERT Jelle", "LTB", "LOTTO BELISOL"],
                        ["92", "KROON Karsten", "TCS", "TINKOFF-SAXO"],
                        ["183", "STEELS Stijn", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["98", "TRUSOV Nikolay", "TCS", "TINKOFF-SAXO"],
                        ["131", "BOZIC Borut", "AST", "ASTANA PRO TEAM"],
                        ["179", "GENE Yohann", "EUC", "TEAM EUROPCAR"],
                        ["22", "DEBUSSCHERE Jens", "LTB", "LOTTO BELISOL"],
                        ["146", "ROJAS GIL Jose Joaquin", "MOV", "MOVISTAR TEAM"],
                        ["118", "VAUGRENARD Benoît", "FDJ", "FDJ.fr"],
                        ["156", "MORI Manuele", "LAM", "LAMPRE-MERIDA"],
                        ["45", "NIZZOLO Giacomo", "TFR", "TREK FACTORY RACING"],
                        ["63", "EARLE Nathan", "SKY", "TEAM SKY"],
                        ["152", "BONIFAZIO Niccolo", "LAM", "LAMPRE-MERIDA"],
                        ["78", "VEELERS Tom", "GIA", "TEAM GIANT-SHIMANO"],
                        ["138", "TLEUBAYEV Ruslan", "AST", "ASTANA PRO TEAM"],
                        ["54", "LONGO BORGHINI Paolo", "CAN", "CANNONDALE"],
                        ["194", "JANS Roy", "WGG", "WANTY - GROUPE GOBERT"],
                        ["175", "JEROME Vincent", "EUC", "TEAM EUROPCAR"],
                        ["77", "STAMSNIJDER Tom", "GIA", "TEAM GIANT-SHIMANO"],
                        ["111", "BOUHANNI Nacer", "FDJ", "FDJ.fr"],
                        ["76", "MEZGEC Luka", "GIA", "TEAM GIANT-SHIMANO"],
                        ["72", "BULGAC Brian", "GIA", "TEAM GIANT-SHIMANO"],
                        ["58", "SABATINI Fabio", "CAN", "CANNONDALE"],
                        ["177", "MARTINEZ Yannick", "EUC", "TEAM EUROPCAR"],
                        ["102", "GOSS Matthew Harley", "OGE", "ORICA GreenEDGE"],
                        ["103", "HAYMAN Mathew", "OGE", "ORICA GreenEDGE"],
                        ["67", "SUTTON Christopher", "SKY", "TEAM SKY"],
                        ["197", "VAN MELSEN Kevin", "WGG", "WANTY - GROUPE GOBERT"],
                        ["165", "GRETSCH Patrick", "ALM", "AG2R LA MONDIALE"],
                        ["176", "LAMOISSON Morgan", "EUC", "TEAM EUROPCAR"],
                        ["91", "BRESCHEL Matti", "TCS", "TINKOFF-SAXO"],
                        ["14", "MOLLEMA Bauke", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["113", "JEANNESSON Arnold", "FDJ", "FDJ.fr"],
                        ["155", "FAVILLI Elia", "LAM", "LAMPRE-MERIDA"],
                        ["187", "VAN BILSEN Kenneth", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["185", "SPRENGERS Thomas", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["180", "PICHOT Alexandre", "EUC", "TEAM EUROPCAR"],
                        ["182", "DECLERCQ Tim", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["12", "LEEZER Thomas", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["136", "HUFFMAN Evan", "AST", "ASTANA PRO TEAM"],
                        ["110", "KRUOPIS Aidis", "OGE", "ORICA GreenEDGE"],
                        ["93", "KOLÁR Michal", "TCS", "TINKOFF-SAXO"],
                        ["32", "BURGHARDT Marcus", "BMC", "BMC RACING TEAM"],
                        ["42", "ALAFACI Eugenio", "TFR", "TREK FACTORY RACING"],
                        ["56", "MARINO Jean Marc", "CAN", "CANNONDALE"],
                        ["73", "CURVERS Roy", "GIA", "TEAM GIANT-SHIMANO"],
                        ["137", "IGLINSKIY Valentin", "AST", "ASTANA PRO TEAM"],
                        ["13", "MARKUS Barry", "BEL", "BELKIN-PRO CYCLING TEAM"],
                        ["174", "HUREL Tony", "EUC", "TEAM EUROPCAR"],
                        ["142", "QUINTANA Dayer", "MOV", "MOVISTAR TEAM"],
                        ["134", "GUARDINI Andrea", "AST", "ASTANA PRO TEAM"],
                        ["168", "KERN Julian", "ALM", "AG2R LA MONDIALE"],
                        ["147", "SANZ Enrique", "MOV", "MOVISTAR TEAM"],
                        ["115", "PICHON Laurent", "FDJ", "FDJ.fr"],
                        ["132", "DYACHENKO Alexandr", "AST", "ASTANA PRO TEAM"],
                        ["163", "DANIEL Maxime", "ALM", "AG2R LA MONDIALE"],
                        ["169", "CHAINEL Steve", "ALM", "AG2R LA MONDIALE"],
                        ["144", "LASTRAS GARCIA Pablo", "MOV", "MOVISTAR TEAM"],
                        ["133", "KAMYSHEV Arman", "AST", "ASTANA PRO TEAM"],
                        ["181", "VAN STAEYEN Michael", "TSV", "TOPSPORT VLAANDEREN - BALOISE"],
                        ["29", "DOCKX Gert", "LTB", "LOTTO BELISOL"],
                        ["173", "DUCHESNE Antoine", "EUC", "TEAM EUROPCAR"]]
        parse(source, expected)
    }

}
