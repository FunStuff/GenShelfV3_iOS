//
// Created by gen on 16/5/30.
//

#ifndef HICORE_CLASS_H
#define HICORE_CLASS_H

#include <string>
#include <map>
#include <list>
#include <mutex>
#include "Hash.h"
#include "StringName.h"

#include "Variant.h"

#include "Define.h"

using namespace std;

namespace hicore  {
    class HObject;
    class ClassDB;
    class HMethod;
    class Property;
    class StringName;

    typedef void * object_type;

    class HClass {
    private:
        const char *ns;
        const char *name;
        StringName *fullname;
        const HClass *parent;
        pointer_map methods;
        pointer_map properties;
        const HMethod *initializer;

        variant_map labels;

        friend class ClassDB;

    protected:
        size_t size;
        HClass() : ns(NULL), parent(NULL), initializer(NULL) {}
        HClass(const char *ns, const char *name);
    public:
        ~HClass();

        /**
         * Get the class name
         */
        _FORCE_INLINE_ const char *getName() const {
            return name;
        }

        /**
         * Get the namespace of class
         */
        _FORCE_INLINE_ const char *getNS() const {
            return ns;
        }

        /**
         * Fullname namespace::name
         */
        _FORCE_INLINE_ const StringName &getFullname() const {
            return *fullname;
        }

        /**
         * Get parent class
         */
        _FORCE_INLINE_ const HClass *getParent() const {
            return  parent;
        }
        /**
         * Make a new instance from class via T()
         */
        virtual object_type instance() const {return NULL;};

        /**
         * The size of target
         */
        _FORCE_INLINE_ size_t getSize() const {
            return size;
        }
        
        /**
         * Check if this class is the subclass of the other class.
         */
        _FORCE_INLINE_ bool isSubclassOf(const HClass *cls) const {
            const HClass *p = getParent();
            while (p) {
                if (p == cls) return true;
                p = p->getParent();
            }
            return false;
        }

        _FORCE_INLINE_ bool isTypeOf(const HClass *cls) const {
            return this == cls || isSubclassOf(cls);
        }
        _FORCE_INLINE_ virtual void del(void *object) const {}

        const HMethod *addMethod(const HMethod *method);

        _FORCE_INLINE_ const HMethod *getMethod(const StringName &name) const {
            auto it = methods.find(name);
            return it == methods.end() ? NULL:(const HMethod *)it->second;
        }
        _FORCE_INLINE_ const void setInitializer(const HMethod *method) {
            initializer = method;
        }
        _FORCE_INLINE_ const HMethod *getInitializer() const {
            return initializer;
        }

        const Property *addProperty(const Property *property);
        const Property *getProperty(const StringName &name) const {
            auto it = properties.find(name);
            return it == properties.end() ? NULL:(const Property *)it->second;
        }

        const pointer_map &getMethods() const;
        const pointer_map &getProperties() const;

        void setLabels(const variant_map &labels);
        _FORCE_INLINE_ bool hasLabel(const StringName &name) const {
            return labels.find(name) != labels.end();
        }
        _FORCE_INLINE_ const Variant &getLabel(const StringName &name) const {
            auto it = labels.find(name);
            return it == labels.end() ? Variant::null() : it->second;
        }

        Variant call(const StringName &name, object_type obj, const Variant **params, int count) const;
    };
    
    
    template<class T>
    struct _class_contrainer {
        static const HClass *_class;
    };
    template<class T>
    const HClass * _class_contrainer<T>::_class = NULL;

    class ClassDB {
    public:
        typedef const HClass *(ClassLoader)();

    private:
        static ClassDB *instance;
        static mutex mtx;

        template<class T>
        class VirtualClass : HClass {
        private:
            friend class ClassDB;
            _FORCE_INLINE_ VirtualClass(const char *ns, const char *name) : HClass(ns, name) {
                size = sizeof(T);
            }
        public:
            _FORCE_INLINE_ virtual void del(void *object) const {
                delete (T*)object;
            }
            virtual object_type instance() const {return NULL;};
        };

        template<class T>
        class TypeClass : VirtualClass<T> {
        private:
            friend class ClassDB;
            _FORCE_INLINE_ TypeClass(const char *ns, const char *name) : VirtualClass<T>(ns, name) {}

        public:
            _FORCE_INLINE_ virtual void del(void *object) const {
                delete (T*)object;
            }
            _FORCE_INLINE_ virtual object_type instance() const {return new T();};
        };

        pointer_map     classes_index;
        pointer_list    classes;
        pointer_map     class_loaders;

        template<class T>
        const HClass *_vcls(const char *ns, const char *name, const HClass *super) {
            void* hash = ns ? h(string(ns) + "::" + name) : h(name);
            auto ite = classes_index.find(hash);

            if (ite == classes_index.end()) {
                HClass *clz = new VirtualClass<T>(ns, name);
                classes_index[hash] = clz;
                classes.push_back(clz);
                clz->parent = super;
                T::onClassLoaded(clz);
                return clz;
            }else
                return (const HClass *) (*ite).second;
        }

        template<class T>
        const HClass *_cls(const char *ns, const char *name, const HClass *super) {
            void *hash = ns ? h(string(ns) + "::" + name) : h(name);
            auto ite = classes_index.find(hash);
            if (ite == classes_index.end()) {
                HClass *clz = (HClass*)new TypeClass<T>(ns, name);
                classes_index[hash] = clz;
                classes.push_back(clz);
                clz->parent = super;
                T::onClassLoaded(clz);
                return clz;
            }else
                return (const HClass *) (*ite).second;
        }

        void loadClasses();

    public:
        _FORCE_INLINE_ ClassDB(){}
        _FORCE_INLINE_ ~ClassDB() {
            for (auto ite = classes.begin(); ite != classes.end(); ++ite) {
                delete((HClass*)*ite);
            }
        }

        _FORCE_INLINE_ static ClassDB *getInstance() {
            bool init = false;
            mtx.lock();
            if (!instance) {
                instance = new ClassDB;
                init = true;
            }
            mtx.unlock();
            if (init) {
                instance->loadClasses();
            }
            return instance;
        }

        const HClass * find_loaded(const StringName &fullname);
        const HClass * find(const StringName &fullname);

        _FORCE_INLINE_ static StringName connect(const char *ns, const char *name) {
            return StringName(ns? (string(ns) + "::" + name).c_str() : name);
        }
        
        /**
         * Register or get a class
         */
        template<class Tc>
        _FORCE_INLINE_ const HClass *cl(const char *ns, const char *name, const HClass *super = NULL)
        {return _cls<Tc>(ns, name, super);}
        template<class Tc>
        _FORCE_INLINE_ const HClass *vr(const char *ns, const char *name, const HClass *super = NULL)
        {return _vcls<Tc>(ns, name, super);}
        

    };

}

#endif //HICORE_CLASS_H
