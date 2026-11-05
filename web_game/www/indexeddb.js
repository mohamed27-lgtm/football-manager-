// ============================================================
//  🗄️ IndexedDB - Club Identity Database Manager
//  يعمل على جميع المتصفحات والأجهزة
// ============================================================

class ClubIdentityDB {
    constructor() {
        this.db = null;
        this.dbName = 'ClubIdentityDB';
        this.version = 2;
        this.initialized = false;
        this.stores = [
            'club',
            'players',
            'friendlyMatches',
            'upcomingMatches',
            'contracts',
            'sponsors',
            'news',
            'negotiations',
            'relations',
            'settings',
            'clubs'
        ];
    }

    // ============================================================
    //  فتح/إنشاء قاعدة البيانات
    // ============================================================
    async init() {
        if (this.initialized && this.db) return this.db;

        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.version);

            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                
                // حذف المتاجر القديمة إذا وجدت (للتحديث)
                for (const storeName of this.stores) {
                    if (db.objectStoreNames.contains(storeName)) {
                        db.deleteObjectStore(storeName);
                    }
                }

                // 1. Club (هوية النادي)
                const clubStore = db.createObjectStore('club', { keyPath: 'id' });
                clubStore.createIndex('name', 'name', { unique: false });

                // 2. Players (اللاعبين)
                const playerStore = db.createObjectStore('players', { keyPath: 'id', autoIncrement: true });
                playerStore.createIndex('name', 'name', { unique: false });
                playerStore.createIndex('position', 'position', { unique: false });
                playerStore.createIndex('isInjured', 'isInjured', { unique: false });
                playerStore.createIndex('contractUntil', 'contractUntil', { unique: false });

                // 3. Friendly Matches (المباريات الودية)
                const matchStore = db.createObjectStore('friendlyMatches', { keyPath: 'id', autoIncrement: true });
                matchStore.createIndex('opponent', 'opponent', { unique: false });
                matchStore.createIndex('date', 'date', { unique: false });
                matchStore.createIndex('result', 'result', { unique: false });

                // 4. Upcoming Matches (المباريات القادمة)
                const upcomingStore = db.createObjectStore('upcomingMatches', { keyPath: 'id', autoIncrement: true });
                upcomingStore.createIndex('opponent', 'opponent', { unique: false });
                upcomingStore.createIndex('date', 'date', { unique: false });
                upcomingStore.createIndex('competition', 'competition', { unique: false });

                // 5. Contracts (العقود)
                const contractStore = db.createObjectStore('contracts', { keyPath: 'id', autoIncrement: true });
                contractStore.createIndex('player', 'player', { unique: false });
                contractStore.createIndex('type', 'type', { unique: false });
                contractStore.createIndex('until', 'until', { unique: false });

                // 6. Sponsors (الرعاة)
                const sponsorStore = db.createObjectStore('sponsors', { keyPath: 'id', autoIncrement: true });
                sponsorStore.createIndex('name', 'name', { unique: false });
                sponsorStore.createIndex('type', 'type', { unique: false });

                // 7. News (الأخبار)
                const newsStore = db.createObjectStore('news', { keyPath: 'id', autoIncrement: true });
                newsStore.createIndex('date', 'date', { unique: false });
                newsStore.createIndex('category', 'category', { unique: false });

                // 8. Negotiations (المفاوضات)
                const negStore = db.createObjectStore('negotiations', { keyPath: 'id', autoIncrement: true });
                negStore.createIndex('player', 'player', { unique: false });
                negStore.createIndex('club', 'club', { unique: false });
                negStore.createIndex('status', 'status', { unique: false });

                // 9. Relations (العلاقات)
                const relStore = db.createObjectStore('relations', { keyPath: 'clubName' });
                relStore.createIndex('relationScore', 'relationScore', { unique: false });

                // 10. Settings (الإعدادات)
                db.createObjectStore('settings', { keyPath: 'key' });

                // 11. Clubs (قائمة الأندية الكاملة)
                const clubsStore = db.createObjectStore('clubs', { keyPath: 'id', autoIncrement: true });
                clubsStore.createIndex('team', 'team', { unique: false });
                clubsStore.createIndex('competition', 'competition', { unique: false });
                clubsStore.createIndex('country', 'country', { unique: false });
                clubsStore.createIndex('capacity', 'capacity', { unique: false });

                console.log('✅ IndexedDB stores created');
            };

            request.onsuccess = (event) => {
                this.db = event.target.result;
                this.initialized = true;
                console.log('✅ IndexedDB initialized successfully');
                resolve(this.db);
            };

            request.onerror = (event) => {
                console.error('❌ IndexedDB error:', event.target.error);
                reject(event.target.error);
            };

            request.onblocked = () => {
                console.warn('⚠️ IndexedDB blocked - close other tabs');
            };
        });
    }

    // ============================================================
    //  دوال عامة للـ CRUD
    // ============================================================

    async add(storeName, data) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readwrite');
            const store = tx.objectStore(storeName);
            const request = store.add(data);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
            tx.oncomplete = () => {};
        });
    }

    async get(storeName, id) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const request = store.get(id);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async getAll(storeName) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => reject(request.error);
        });
    }

    async put(storeName, data) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readwrite');
            const store = tx.objectStore(storeName);
            const request = store.put(data);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async delete(storeName, id) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readwrite');
            const store = tx.objectStore(storeName);
            const request = store.delete(id);
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }

    async deleteAll(storeName) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readwrite');
            const store = tx.objectStore(storeName);
            const request = store.clear();
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }

    async getByIndex(storeName, indexName, value) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const index = store.index(indexName);
            const request = index.getAll(value);
            request.onsuccess = () => resolve(request.result || []);
            request.onerror = () => reject(request.error);
        });
    }

    async count(storeName) {
        await this.init();
        return new Promise((resolve, reject) => {
            const tx = this.db.transaction(storeName, 'readonly');
            const store = tx.objectStore(storeName);
            const request = store.count();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    // ============================================================
    //  دوال خاصة بـ Club Identity
    // ============================================================

    // --- Club ---
    async saveClub(clubData) {
        return this.put('club', { id: 'main', ...clubData });
    }

    async getClub() {
        return this.get('club', 'main');
    }

    // --- Players ---
    async addPlayer(player) {
        return this.add('players', player);
    }

    async getAllPlayers() {
        return this.getAll('players');
    }

    async getInjuredPlayers() {
        return this.getByIndex('players', 'isInjured', true);
    }

    async updatePlayer(player) {
        return this.put('players', player);
    }

    async deletePlayer(id) {
        return this.delete('players', id);
    }

    // --- Friendly Matches ---
    async addFriendlyMatch(match) {
        return this.add('friendlyMatches', match);
    }

    async getAllFriendlyMatches() {
        return this.getAll('friendlyMatches');
    }

    async getFriendlyMatchByOpponent(opponent) {
        return this.getByIndex('friendlyMatches', 'opponent', opponent);
    }

    // --- Upcoming Matches ---
    async addUpcomingMatch(match) {
        return this.add('upcomingMatches', match);
    }

    async getAllUpcomingMatches() {
        return this.getAll('upcomingMatches');
    }

    async getUpcomingMatchesByCompetition(competition) {
        return this.getByIndex('upcomingMatches', 'competition', competition);
    }

    // --- Contracts ---
    async addContract(contract) {
        return this.add('contracts', contract);
    }

    async getAllContracts() {
        return this.getAll('contracts');
    }

    async getContractsByPlayer(player) {
        return this.getByIndex('contracts', 'player', player);
    }

    // --- Sponsors ---
    async addSponsor(sponsor) {
        return this.add('sponsors', sponsor);
    }

    async getAllSponsors() {
        return this.getAll('sponsors');
    }

    async getSponsorsByType(type) {
        return this.getByIndex('sponsors', 'type', type);
    }

    // --- News ---
    async addNews(newsItem) {
        return this.add('news', newsItem);
    }

    async getAllNews() {
        return this.getAll('news');
    }

    async getLatestNews(limit = 5) {
        const all = await this.getAll('news');
        return all.sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, limit);
    }

    // --- Negotiations ---
    async addNegotiation(negotiation) {
        return this.add('negotiations', negotiation);
    }

    async getAllNegotiations() {
        return this.getAll('negotiations');
    }

    async getActiveNegotiations() {
        return this.getByIndex('negotiations', 'status', 'active');
    }

    async updateNegotiationStatus(id, status) {
        const neg = await this.get('negotiations', id);
        if (neg) {
            neg.status = status;
            return this.put('negotiations', neg);
        }
        return null;
    }

    // --- Relations ---
    async updateRelation(clubName, score) {
        return this.put('relations', { clubName, relationScore: score });
    }

    async getAllRelations() {
        return this.getAll('relations');
    }

    async getRelation(clubName) {
        return this.get('relations', clubName);
    }

    async getAverageRelation() {
        const relations = await this.getAll('relations');
        if (relations.length === 0) return 0;
        const total = relations.reduce((sum, r) => sum + r.relationScore, 0);
        return total / relations.length;
    }

    // --- Settings ---
    async getSetting(key) {
        return this.get('settings', key);
    }

    async saveSetting(key, value) {
        return this.put('settings', { key, value });
    }

    async getAllSettings() {
        return this.getAll('settings');
    }

    // --- Clubs (قائمة الأندية) ---
    async addClub(club) {
        return this.add('clubs', club);
    }

    async addClubsBulk(clubs) {
        await this.init();
        const tx = this.db.transaction('clubs', 'readwrite');
        const store = tx.objectStore('clubs');
        
        for (const club of clubs) {
            store.add(club);
        }
        
        return new Promise((resolve, reject) => {
            tx.oncomplete = () => resolve(clubs.length);
            tx.onerror = () => reject(tx.error);
        });
    }

    async getAllClubs() {
        return this.getAll('clubs');
    }

    async getClubsByCompetition(competition) {
        return this.getByIndex('clubs', 'competition', competition);
    }

    async getClubsByCountry(country) {
        return this.getByIndex('clubs', 'country', country);
    }

    async searchClubs(query) {
        const all = await this.getAll('clubs');
        const lower = query.toLowerCase();
        return all.filter(c => 
            c.team.toLowerCase().includes(lower) ||
            c.competition.toLowerCase().includes(lower) ||
            c.country.toLowerCase().includes(lower)
        );
    }

    async getClubByTeam(team) {
        const all = await this.getAll('clubs');
        return all.find(c => c.team === team) || null;
    }

    async deleteAllClubs() {
        return this.deleteAll('clubs');
    }

    // ============================================================
    //  تهيئة البيانات الافتراضية
    // ============================================================
    async initializeDefaultData() {
        const existingClub = await this.getClub();
        if (existingClub) {
            console.log('📌 Data already exists, skipping initialization');
            return;
        }

        console.log('🔄 Initializing default data...');

        // 1. بيانات النادي
        await this.saveClub({
            name: 'نادي المستقبل',
            president: 'د. عبدالله السالم',
            coach: 'خوان كارلوس',
            philosophy: 'هجومي، استحواذ، تطوير الشباب',
            budget: 150.0,
            reputation: 50,
            fatigue: 20,
            stadium: {
                name: 'ملعب النادي',
                capacity: 30000,
                location: 'الرياض'
            },
            tickets: {
                averagePrice: 45,
                seasonTickets: 15000,
                soldOutPercentage: 85
            },
            weather: {
                temperature: 28,
                condition: 'مشمس',
                city: 'الرياض'
            },
            fans: 25000,
            goals: '🏆 الفوز بالدوري، التأهل لدوري الأبطال'
        });

        // 2. بيانات اللاعبين
        const defaultPlayers = [
            { name: 'أحمد السعيد', position: 'مهاجم', age: 27, marketValue: 5.0, isInjured: false, contractUntil: '2028-06-30' },
            { name: 'محمد العلي', position: 'وسط', age: 24, marketValue: 4.2, isInjured: false, contractUntil: '2027-06-30' },
            { name: 'سعود الحربي', position: 'مدافع', age: 29, marketValue: 3.8, isInjured: true, contractUntil: '2026-06-30' },
            { name: 'فهد الغامدي', position: 'حارس', age: 32, marketValue: 2.5, isInjured: false, contractUntil: '2025-06-30' },
            { name: 'يوسف الدوسري', position: 'وسط', age: 23, marketValue: 6.0, isInjured: false, contractUntil: '2029-06-30' }
        ];
        for (const player of defaultPlayers) {
            await this.addPlayer(player);
        }

        // 3. بيانات المباريات الودية
        await this.addFriendlyMatch({
            opponent: 'الهلال',
            date: '2026-02-15',
            result: '2-1',
            profit: 0.45,
            repImpact: 3.2,
            fatigueCost: 12
        });

        // 4. بيانات المباريات القادمة
        await this.addUpcomingMatch({
            opponent: 'الأهلي',
            date: '2026-03-01',
            competition: 'الدوري',
            venue: 'home',
            time: '20:00'
        });

        // 5. بيانات العقود
        await this.addContract({
            player: 'أحمد السعيد',
            type: 'تمديد',
            until: '2028-06-30',
            value: 8.5,
            signed: '2026-01-15'
        });

        // 6. بيانات الرعاة
        await this.addSponsor({
            name: 'الشركة الوطنية',
            type: 'رئيسي',
            annualValue: 15.0,
            until: '2028-12-31'
        });

        // 7. بيانات العلاقات
        await this.updateRelation('الهلال', 75);
        await this.updateRelation('النصر', 60);

        // 8. بيانات المفاوضات
        await this.addNegotiation({
            player: 'لاعب جديد',
            club: 'الهلال',
            status: 'active',
            type: 'انتقال',
            fee: 12.5,
            lastUpdate: '2026-02-18'
        });

        // 9. إعدادات
        await this.saveSetting('lastUpdate', new Date().toISOString());
        await this.saveSetting('version', '2.0');

        console.log('✅ Default data initialized successfully!');
    }

    // ============================================================
    //  تصدير/استيراد البيانات (Backup)
    // ============================================================
    async exportAllData() {
        const data = {};
        for (const store of this.stores) {
            data[store] = await this.getAll(store);
        }
        return data;
    }

    async importAllData(data) {
        for (const store of this.stores) {
            if (data[store]) {
                await this.deleteAll(store);
                for (const item of data[store]) {
                    await this.add(store, item);
                }
            }
        }
        console.log('✅ Data imported successfully');
    }

    // ============================================================
    //  حذف قاعدة البيانات بالكامل
    // ============================================================
    async deleteDatabase() {
        return new Promise((resolve, reject) => {
            if (this.db) {
                this.db.close();
                this.db = null;
                this.initialized = false;
            }
            const request = indexedDB.deleteDatabase(this.dbName);
            request.onsuccess = () => {
                console.log('✅ Database deleted successfully');
                resolve();
            };
            request.onerror = () => {
                reject(request.error);
            };
            request.onblocked = () => {
                console.warn('⚠️ Database deletion blocked - close other tabs');
                resolve();
            };
        });
    }

    // ===========================================================
        //  التحقق من صحة الاتصال
    // ============================================================
    async checkConnection() {
        try {
            await this.init();
            const count = await this.count('club');
            return { connected: true, records: count };
        } catch (e) {
            return { connected: false, error: e.message };
        }
    }
}

// ============================================================
//  إنشاء نسخة واحدة من قاعدة البيانات
// ============================================================
const clubDB = new ClubIdentityDB();

// تصدير للاستخدام في المتصفح
window.clubDB = clubDB;

// ============================================================
//  دوال مساعدة للاستخدام السريع
// ============================================================

// تهيئة سريعة
async function initDB() {
    await clubDB.init();
    await clubDB.initializeDefaultData();
    return clubDB;
}

// حفظ بيانات النادي بسرعة
async function saveClubData(data) {
    const current = await clubDB.getClub() || {};
    await clubDB.saveClub({ ...current, ...data });
    return clubDB.getClub();
}

// إضافة لاعب بسرعة
async function addPlayerQuick(name, position, age, marketValue) {
    return clubDB.addPlayer({
        name,
        position,
        age: age || 25,
        marketValue: marketValue || 1.0,
        isInjured: false,
        contractUntil: '2027-06-30'
    });
}

// إضافة مباراة ودية بسرعة
async function addFriendlyQuick(opponent, result, profit) {
    return clubDB.addFriendlyMatch({
        opponent,
        date: new Date().toISOString().slice(0, 10),
        result: result || '0-0',
        profit: profit || 0.1,
        repImpact: 1.0,
        fatigueCost: 5
    });
}

// تصدير جميع الدوال
window.initDB = initDB;
window.saveClubData = saveClubData;
window.addPlayerQuick = addPlayerQuick;
window.addFriendlyQuick = addFriendlyQuick;

console.log('✅ ClubIdentityDB loaded successfully!');
console.log('📖 Use clubDB object to interact with the database');
console.log('💡 Example: await clubDB.getAllPlayers()');